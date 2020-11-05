#!/bin/bash
# Setup the build container with
#    docker build . --no-cache -t consected/restructure-build

source /shared/build-vars.sh
export HOME=/root

yum update -y
yum install -y deltarpm sudo
yum update

curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
curl --silent --location https://rpm.nodesource.com/setup_12.x | bash -
yum install -y git yarn \
  postgresql-server postgresql-devel postgresql-contrib \
  openssl-devel readline-devel zlib-devel \
  gcc gcc-c++ make which \
  tar bzip2

# For testing
# yum install -y firefox Xvfb x11vnc

# Install rbenv
git clone https://github.com/rbenv/rbenv.git ${HOME}/.rbenv
cd ${HOME}/.rbenv && src/configure && make -C src
echo 'eval "$(rbenv init -)"' >> ${HOME}/.bash_profile
export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init -)"
. /root/.bash_profile
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
mkdir -p "$(rbenv root)"/plugins
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
rbenv install --list
rbenv rehash

# Install ruby, etc
if [ "$(rbenv local)" != "${RUBY_V}" ]; then
  rbenv install ${RUBY_V}
  rbenv global ${RUBY_V}
  gem install bundler
fi

# Setup Postgres
sudo -u postgres initdb /var/lib/pgsql/data/
sudo -u postgres pg_ctl start -D /var/lib/pgsql/data -s -o "-p 5432" -w -t 300
