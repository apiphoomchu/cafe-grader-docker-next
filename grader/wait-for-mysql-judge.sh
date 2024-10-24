#!/bin/bash

source /etc/profile.d/rvm.sh
rvm use 3.2.1 --default

# Set bundle config
export BUNDLE_PATH=/usr/local/rvm/gems/ruby-3.2.1
export GEM_HOME=/usr/local/rvm/gems/ruby-3.2.1
export GEM_PATH=/usr/local/rvm/gems/ruby-3.2.1

echo ""
echo "Waiting for mysql . . ."
until mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h db > /dev/null 2>&1
do
echo "Waiting for mysql . . ."
sleep 1
done
echo "MySQL is Ready"

while [ -f "/cafe_grader/judge/setup.sh" ];
do
echo "Waiting for setup . . ."
sleep 1
done
echo "Environment is ready"

cd /cafe_grader/judge/scripts && \
BUNDLE_GEMFILE=/cafe_grader/web/Gemfile exec /bin/bash -l -c "source /etc/profile.d/rvm.sh && bundle exec ruby grader grading queue --err-log"