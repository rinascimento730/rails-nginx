#!/bin/bash

# ローカルタイムを【Japan】に変更
sudo ln -sf /usr/share/zoneinfo/Japan /etc/localtime

# ハードウェアクロックを【Japan】に変更
sudo sed -i "s/\"UTC\"/\"Japan\"/g" /etc/sysconfig/clock

# yum upgrade
sudo yum -y upgrade

# install dev tools
sudo yum -y install git openssl-devel lsof

# install Nginx
sudo yum -y install nginx
sudo chkconfig nginx on

# install MySQL
sudo yum -y install http://dev.mysql.com/get/mysql-community-release-el6-5.noarch.rpm
sudo yum -y install mysql mysql-devel mysql-server mysql-utilities
sudo chkconfig mysqld on
sudo service mysqld start

# rubyのインストール必要な所々のソフトウェアをインストール
sudo yum -y install gcc-c++ glibc-headers readline libyaml-devel readline-devel zlib zlib-devel libffi-devel libxml2 libxslt libxml2-devel libxslt-devel libcurl-devel pygpgme curl

# install rbenv
git clone git://github.com/sstephenson/rbenv.git ~/.rbenv

# install ruby-build
git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
sudo ~/.rbenv/plugins/ruby-build/install.sh

# /etc/profile.d/rbenv.shに以下の内容を記述
sh -c 'cat <<EOF>> ~/.bash_profile
export RBENV_ROOT="${HOME}/.rbenv"
export PATH="\${RBENV_ROOT}/bin:${PATH}"
eval "\$(rbenv init -)"
EOF'

# reload ~/.bash_profile
source ~/.bash_profile

# install ruby2.5.1
rbenv install 2.5.1
rbenv global 2.5.1
rbenv rehash

# install rails
gem update --system
gem install --no-ri --no-rdoc rails
rbenv rehash

RAILS_APP='/vagrant/rails-app'
<< COMMENTOUT
# rails app setting
cd /vagrant
rails new rails-app -d mysql --skip-test --skip-bundle
sh -c "cat <<EOF>> ${RAILS_APP}/Gemfile
gem 'therubyracer', platforms: :ruby
EOF"
COMMENTOUT

# bundle install
cd ${RAILS_APP}
bundle install --path vendor/bundle
rbenv rehash

# puma setting
mkdir -p /tmp/sockets
mkdir -p ${RAILS_APP}/tmp/pids
<< COMMENTOUT
cat <<EOF>> ${RAILS_APP}/config/puma.rb
bind "unix:/tmp/sockets/puma.sock"

# uncomment and customize to run in non-root path
# note that config/puma.yml web path should also be changed
application_path = "#{File.expand_path("../..", __FILE__)}"

# Daemonize the server into the background. Highly suggest that
# this be combined with “pidfile” and “stdout_redirect”.
#
# The default is “false”.
#
daemonize true

# Store the pid of the server in the file at “path”.
#
pidfile "#{application_path}/tmp/pids/puma.pid"
EOF
COMMENTOUT

# puma service setting
sudo cp /vagrant/init.d/puma /etc/init.d
sudo chown root /etc/init.d/puma
sudo chmod +x /etc/init.d/puma
sudo service puma start
sudo chkconfig puma on

# chown nginx files   
sudo chown -R vagrant /var/lib/nginx
sudo cp /vagrant/nginx/nginx.conf /etc/nginx/nginx.conf
sudo service nginx start

# Create Mysql User for Rails
mysql -u root < /vagrant/db/create_user_vagrant.sql

# Create database
cd ${RAILS_APP}
bundle exec rake db:create












