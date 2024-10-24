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

# Change to the scripts directory
cd /cafe_grader/judge/scripts

# Run the grader daemon with proper Ruby environment
/usr/local/rvm/bin/rvm-shell 3.2.1 -c "./grader grading queue --err-log"

# For non-SSL purpose
#rails s -p 3000 -b '0.0.0.0'
# with-ssl-cert (Sirawit, 8/4/2019)
# thin -p 3000 --ssl --ssl-key-file /cafe_grader/server.key --ssl-cert-file /cafe_grader/server.crt start 2>&1