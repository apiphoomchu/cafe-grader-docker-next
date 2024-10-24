#!/bin/bash

# Source RVM and Ruby environment
source /etc/profile.d/rvm.sh
source /usr/local/rvm/scripts/rvm
rvm use 3.2.1

# Set proper environment variables
export RAILS_ENV=production
export PATH="/usr/local/rvm/gems/ruby-3.2.1/bin:/usr/local/rvm/gems/ruby-3.2.1@global/bin:/usr/local/rvm/rubies/ruby-3.2.1/bin:$PATH"
export GEM_HOME="/usr/local/rvm/gems/ruby-3.2.1"
export GEM_PATH="/usr/local/rvm/gems/ruby-3.2.1:/usr/local/rvm/gems/ruby-3.2.1@global"

echo ""
echo "Waiting for mysql . . ."
until mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h db > /dev/null 2>&1
do
  echo "Waiting for mysql . . ."
  sleep 1
done
echo "MySQL is Ready"

if [ -f "/cafe_grader/judge/setup.sh" ]; then
  /bin/bash /cafe_grader/judge/setup.sh
fi

# Change to the web directory
cd /cafe_grader/web


# Try to run database migrations
bundle exec rake db:migrate 2>/dev/null || true

# Try to precompile assets
bundle exec rake assets:precompile 2>/dev/null || true

# Start Rails server
# For non-SSL purpose
bundle exec rails s -p 8080 -b '0.0.0.0'
# with-ssl-cert (Sirawit, 8/4/2019)
# thin -p 3000 --ssl --ssl-key-file /cafe_grader/server.key --ssl-cert-file /cafe_grader/server.crt start 2>&1