#
RUBY_V=3.4.2
GIT_EMAIL=phil_ayres@hms.harvard.edu
BUILD_GIT_BRANCH=new-master
REPO_URL="https://github.com/hmsrc/fphs-restructure.git"
PROD_REPO_URL="https://github.com/hmsrc/fphs-rails-app.git"
DOCS_REPO_URL="https://github.com/hmsrc/fphs-app-docs.git"
APPS_REPO_URL="https://github.com/hmsrc/fphs-app-configs.git"

# ONLY_PUSH_TO_PROD_REPO=true
ONLY_PUSH_ASSETS_TO_PROD_REPO=true

# Change to 'true' to run rspec tests
#RUN_TESTS=true

DB_NAME=restr_db
TEST_DB_NAME=${DB_NAME}_test
DB_USER=$(whoami)
DB_PASSWORD=root
DB_DEFAULT_SCHEMA=ml_app
APP_DB_SEARCH_PATH=ml_app,ref_data
DUMP_SCHEMAS="ml_app ref_data"
RSPEC_OPTIONS='--exclude-pattern "**/features/**/*_spec.rb"'
SKIP_BUNDLE_AUDIT=true
