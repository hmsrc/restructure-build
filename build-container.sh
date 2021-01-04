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
yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

#sudo yum -y install epel-release centos-release-scl-rh yum-utils
sudo yum-config-manager --enable pgdg10

yum install -y git yarn \
  postgresql10-server postgresql10 postgresql10-devel postgresql10-contrib llvm-toolset-7-clang \
  openssl-devel readline-devel zlib-devel \
  gcc gcc-c++ make which mlocate \
  tar bzip2 \
  words

# For UI features testing
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
sudo -u postgres /usr/pgsql-10/bin/initdb /var/lib/pgsql/data
sudo -u postgres /usr/pgsql-10/bin/pg_ctl start -D /var/lib/pgsql/data -s -o "-p 5432" -w -t 300
psql --version
sudo -u postgres psql -c 'SELECT version();' 2>&1
