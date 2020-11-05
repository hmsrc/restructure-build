#!/bin/bash

source build-vars.sh

export HOME=/root
export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
source $HOME/.bash_profile
BUILD_DIR=/output/restructure

ls /

cp /shared/.netrc ${HOME}/.netrc
chmod 600 ${HOME}/.netrc

# Setup App environment
export FPHS_POSTGRESQL_DATABASE=${DB_NAME}
export FPHS_POSTGRESQL_USERNAME=${DB_USER}
export FPHS_POSTGRESQL_PASSWORD=${DB_PASSWORD}
export FPHS_POSTGRESQL_SCHEMA=${APP_DB_SEARCH_PATH}
export FPHS_POSTGRESQL_PORT=5432
export FPHS_POSTGRESQL_HOSTNAME=localhost
export FPHS_RAILS_DEVISE_SECRET_KEY='rake'
export FPHS_RAILS_SECRET_KEY_BASE='rake'
export RAILS_ENV=production

# Get source
cd ${HOME}
git config --global user.email ${GIT_EMAIL}
git config --global user.name "Restructure Build Process"
git clone ${REPO_URL} ${BUILD_DIR}
cd ${BUILD_DIR}

# Checkout branch to build
git checkout ${BUILD_GIT_BRANCH} || git checkout -b ${BUILD_GIT_BRANCH} --track origin/${BUILD_GIT_BRANCH}
pwd
ls
mkdir -p tmp
chmod 774 tmp
mkdir -p log
chmod 774 log
touch log/delayed_job.log
chmod 664 log/delayed_job.log

if [ ! -f Gemfile ]; then
  echo "No Gemfile found after checking out branch ${BUILD_GIT_BRANCH} to $(pwd)"
  exit 1
fi

# Setup remote repos
if [ "${PROD_REPO_URL}" ]; then
  git remote set-url --add origin ${PROD_REPO_URL}
  git remote set-url --push --add origin ${PROD_REPO_URL}
  git remote set-url --delete origin ${REPO_URL}
  git merge origin/${BUILD_GIT_BRANCH} -m "Merge remote" &&
    git commit -a -m "Commit" &&
    git push -f
fi

# Bundle and Yarn
cd ${BUILD_DIR}
rbenv local ${RUBY_V}
which ruby
ruby --version

gem install bundler
bundle install --path vendor/bundle
bundle package --all

if [ ! -d vendor/bundle ]; then
  echo "No vendor/bundle after bundle install"
  exit 1
fi

bin/yarn install

if [ ! -d node_modules ]; then
  echo "No node_modules after yarn install"
  exit 1
fi

# Setup add DB
echo "localhost:5432:*:${DB_USER}:${DB_PASSWORD}" > ${HOME}/.pgpass
chmod 600 /root/.pgpass

echo "Create user ${DB_USER} and drop schema in DB ${DB_NAME}"
sudo -u postgres psql << EOF
CREATE USER IF NOT EXISTS ${DB_USER} WITH LOGIN PASSWORD '${DB_PASSWORD}';
DROP DATABASE IF EXISTS ${DB_NAME};
CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
EOF

echo "Run current_schema.sql"
psql -d ${DB_NAME} -U ${DB_USER} -h localhost < db/dumps/current_schema.sql

echo "Grant privileges, setup pgcrypto and replace migration list"
sudo -u postgres psql ${DB_NAME} << EOF
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ${DB_DEFAULT_SCHEMA} TO ${DB_USER};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ${DB_DEFAULT_SCHEMA} TO ${DB_USER};
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA ${DB_DEFAULT_SCHEMA} TO ${DB_USER};
GRANT ALL PRIVILEGES ON SCHEMA ${DB_DEFAULT_SCHEMA} TO ${DB_USER};

CREATE EXTENSION if not exists pgcrypto;
COPY ${DB_DEFAULT_SCHEMA}.schema_migrations (version) FROM 'db/dumps/fphs_miglist.txt'; 
EOF

# Replace the migration list
cd ${BUILD_DIR}
bundle exec rake db:migrate
bundle exec rake db:seed
psql -d ${DB_NAME} -U ${DB_USER} -h localhost -c "SELECT * FROM ${DB_DEFAULT_SCHEMA}.schema_migrations ORDER BY version" | grep -oP '([0-9]{10,20})' > db/dumps/fphs_miglist.txt

if [ ! -f db/dumps/fphs_miglist.txt ] || [ ! -s db/dumps/fphs_miglist.txt ]; then
  echo "Failed to create migration list"
  exit 1
fi

# Upversion code
TARGET_VERSION=$(ruby app-scripts/upversion.rb)

if [ -z "${TARGET_VERSION}" ]; then
  echo "TARGET_VERSION not set"
  exit 1
fi

# Update CHANGELOG
sed -i -E "s/## (Unreleased)/\1[${TARGET_VERSION}] - $(date +%Y-%m-%d)\2/" file.xml

# Commit the new version
git commit version.txt CHANGELOG.md -m "new version created $(cat version.txt)"

# Cleanup assets
rm -rf public/assets
bundle exec rake assets:clobber
bundle exec rake assets:precompile --trace
git add public/assets

# Run static analysis tests
bundle exec brakeman -o security/brakeman-output-${TARGET_VERSION}.md
bundle exec bundle-audit update > security/bundle-audit-update-${TARGET_VERSION}.md
bundle exec bundle-audit check > security/bundle-audit-output-${TARGET_VERSION}.md

# Prep new DB dump
rm -f db/dumps/current_schema.sql
echo "begin;" > /tmp/current_schema.sql
pg_dump -O -n ${DB_DEFAULT_SCHEMA} -d ${DB_NAME} -s -x >> /tmp/current_schema.sql
echo "commit;" >> /tmp/current_schema.sql
mv /tmp/current_schema.sql db/dumps/
bundle exec rake db:structure:dump

sudo -u postgres psql ${DB_NAME} << EOF
drop database if exists fpa_test;"
EOF

# Set and run tests
app-scripts/create-test-db.sh
FPHS_ADMIN_SETUP=yes RAILS_ENV=test bundle exec rake db:seed
RAILS_ENV=test bundle exec rspec ${RSPEC_OPTIONS}

# Commit the new assets and schema
git add .
git commit -m "Built and tested release-ready version '${TARGET_VERSION}'"
git tag -a "${TARGET_VERSION}" -m "Push release"
git push -f
git push -f origin "${TARGET_VERSION}"
echo "${TARGET_VERSION}" > /root/build_version.txt
