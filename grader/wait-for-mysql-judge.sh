#!/bin/bash
source /etc/profile.d/rvm.sh
rvm use 2.3.0--default

# Set bundle config for judge
export BUNDLE_PATH=/usr/local/rvm/gems/ruby-2.3.0
export GEM_HOME=/usr/local/rvm/gems/ruby-2.3.0
export GEM_PATH=/usr/local/rvm/gems/ruby-2.3.0

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
exec /bin/bash -l -c "source /etc/profile.d/rvm.sh && rvm use 2.1.5 && ruby grader grading queue --err-log"