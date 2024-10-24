#!/bin/bash

source /etc/profile.d/rvm.sh
rvm use 3.2.1 --default

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
exec /bin/bash -l -c "source /etc/profile.d/rvm.sh && ruby grader grading queue --err-log"