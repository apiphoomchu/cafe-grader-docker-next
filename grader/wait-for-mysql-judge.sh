#!/bin/bash

# Source RVM and Ruby environment
source /etc/profile.d/rvm.sh
source /usr/local/rvm/scripts/rvm
rvm use 3.2.1

echo ""
echo "Waiting for mysql . . ."
until mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h db > /dev/null 2>&1
do
  echo "Waiting for mysql . . ."
  sleep 1
done
echo "MySQL is Ready"

# [7/2/2020] Judge Daemon
while [ -f "/cafe_grader/judge/setup.sh" ];
do
  echo "Waiting for setup . . ."
  sleep 1
done
echo "Environment is ready"

# Set proper environment variables
export RAILS_ENV=production
export PATH="/usr/local/rvm/gems/ruby-3.2.1/bin:/usr/local/rvm/gems/ruby-3.2.1@global/bin:/usr/local/rvm/rubies/ruby-3.2.1/bin:$PATH"
export GEM_HOME="/usr/local/rvm/gems/ruby-3.2.1"
export GEM_PATH="/usr/local/rvm/gems/ruby-3.2.1:/usr/local/rvm/gems/ruby-3.2.1@global"

# Ensure directories exist and have proper permissions
mkdir -p /cafe_grader/judge/log
chmod -R 777 /cafe_grader/judge/log
chmod -R 755 /cafe_grader/judge/scripts

# Change to the scripts directory
cd /cafe_grader/judge/scripts

# Run the grader daemon with proper Ruby environment
bundle exec ./grader grading queue --err-log