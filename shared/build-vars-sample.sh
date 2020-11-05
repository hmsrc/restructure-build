RUBY_V=2.6.6
GIT_EMAIL=youremail
BUILD_GIT_BRANCH=new-master
REPO_URL="https://github.com/somerep"
# If you want to commit the build to a different repo, uncomment and add it here
# PROD_REPO_URL="https://github.com/prodrepo"

DB_NAME=restr_db
DB_USER=$(whoami)
DB_PASSWORD=root
DB_DEFAULT_SCHEMA=ml_app
APP_DB_SEARCH_PATH=ml_app
RSPEC_OPTIONS='rspec_extra_options: --exclude-pattern "**/features/**/*_spec.rb"'
