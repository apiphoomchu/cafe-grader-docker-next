FROM ubuntu:16.04
ENV DEBIAN_FRONTEND=noninteractive
ARG MYSQL_DATABASE
ENV MYSQL_DATABASE $MYSQL_DATABASE
ARG MYSQL_USER
ENV MYSQL_USER $MYSQL_USER
ARG MYSQL_PASSWORD
ENV MYSQL_PASSWORD $MYSQL_PASSWORD

# Set timezone
ENV TZ=Asia/Bangkok
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    mysql-client \
    g++ gcc apache2 libmysqlclient20 \
    git-core openssl libreadline6 libreadline6-dev \
    zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev \
    sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev \
    ncurses-dev automake libtool bison subversion \
    pkg-config unzip pyflakes default-jdk \
    libmysqld-dev mercurial python-setuptools python-dev python3-numpy \
    build-essential libpq-dev nodejs curl tzdata && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /

# Remove old Node.js and install newer version
RUN apt-get update && apt-get remove -y nodejs || true
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

# Import RVM keys
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
    curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -

# Install RVM and Ruby versions with proper bundler configurations
ENV RUBY_VERSION_WEB=3.2.1
ENV RUBY_VERSION_JUDGE=2.1.5
RUN curl -sSL https://get.rvm.io | bash -s stable && \
    /bin/bash -l -c "source /etc/profile.d/rvm.sh && \
    rvm install ${RUBY_VERSION_WEB} && \
    rvm install ${RUBY_VERSION_JUDGE} && \
    rvm use ${RUBY_VERSION_WEB} --default && \
    rvm rubygems latest && \
    gem update --system && \
    gem install bundler:2.4.22 && \
    rvm use ${RUBY_VERSION_JUDGE} && \
    gem install bundler -v '1.17.3' && \
    ruby -v"

# Create necessary directories with proper permissions
RUN mkdir -p /cafe_grader && \
    chmod -R 777 /cafe_grader

# Judge setup with older Ruby version
RUN mkdir -p /cafe_grader/judge
WORKDIR /cafe_grader/judge
ADD scripts /cafe_grader/judge/scripts
RUN mkdir -p raw ev-exam ev result log && \
    chmod -R 777 /cafe_grader/judge

# Configure judge environment with proper Ruby and bundler
WORKDIR /cafe_grader/judge
RUN /bin/bash -l -c "source /etc/profile.d/rvm.sh && \
    rvm use ${RUBY_VERSION_JUDGE} && \
    cp scripts/config/env_exam.rb.SAMPLE scripts/config/env_exam.rb && \
    cp scripts/config/env_grading.rb.SAMPLE scripts/config/env_grading.rb && \
    echo \"RAILS_ROOT = '/cafe_grader/web'\" > scripts/config/environment.rb && \
    echo \"GRADER_ROOT = '/cafe_grader/judge/scripts'\" >> scripts/config/environment.rb && \
    echo \"require File.join(File.dirname(__FILE__),'../lib/boot')\" >> scripts/config/environment.rb && \
    echo \"require File.dirname(__FILE__) + \\\"/env_#{GRADER_ENV}.rb\\\"\" >> scripts/config/environment.rb"

# Compile the grader box
RUN gcc -std=c99 -o scripts/std-script/box scripts/std-script/box64-new.c

# Set up judge Gemfiles and install dependencies
RUN /bin/bash -l -c "source /etc/profile.d/rvm.sh && \
    rvm use ${RUBY_VERSION_JUDGE} && \
    echo 'source \"https://rubygems.org\"' > Gemfile && \
    echo 'gem \"mysql2\", \"~> 0.3.21\"' >> Gemfile && \
    echo 'gem \"rails\", \"~> 4.2.0\"' >> Gemfile && \
    bundle _1.17.3_ install --path vendor/bundle"

WORKDIR /cafe_grader/judge/scripts
RUN /bin/bash -l -c "source /etc/profile.d/rvm.sh && \
    rvm use ${RUBY_VERSION_JUDGE} && \
    echo 'source \"https://rubygems.org\"' > Gemfile && \
    echo 'gem \"mysql2\", \"~> 0.3.21\"' >> Gemfile && \
    echo 'gem \"rails\", \"~> 4.2.0\"' >> Gemfile && \
    bundle _1.17.3_ install --path vendor/bundle"

# Web setup
WORKDIR /cafe_grader
ADD web /cafe_grader/web
COPY worker.yml /cafe_grader/web/config/worker.yml
RUN cp web/config/application.rb.SAMPLE web/config/application.rb && \
    cp web/config/initializers/cafe_grader_config.rb.SAMPLE web/config/initializers/cafe_grader_config.rb && \
    export timezone=`cat /etc/timezone` && \
    export replace="s!'UTC'!'$timezone'!g" && \
    sed -i $replace web/config/application.rb

WORKDIR /cafe_grader/web

# Update config files
RUN echo "Object.instance_eval{remove_const :GRADER_ROOT_DIR}" >> config/initializers/cafe_grader_config.rb && \
    echo "Object.instance_eval{remove_const :GRADING_RESULT_DIR}" >> config/initializers/cafe_grader_config.rb && \
    echo "GRADER_ROOT_DIR = '/cafe_grader/judge'" >> config/initializers/cafe_grader_config.rb && \
    echo "GRADING_RESULT_DIR = '/cafe_grader/judge/result'" >> config/initializers/cafe_grader_config.rb

# Setup bundle config for web
RUN mkdir -p /usr/local/bundle && \
    chmod -R 777 /usr/local/bundle

# Install gems for web with newer Ruby
WORKDIR /cafe_grader/web
RUN /bin/bash -l -c "source /etc/profile.d/rvm.sh && \
    rvm use ${RUBY_VERSION_WEB} && \
    bundle config set --local path '/usr/local/bundle' && \
    bundle install --jobs 4 --retry 3"

# Database setup
RUN /bin/bash -l -c "source /etc/profile.d/rvm.sh && \
    rvm use ${RUBY_VERSION_WEB} && \
    echo 'development:' > config/secrets.yml && \
    echo '  secret_key_base: '$(rake secret) >> config/secrets.yml && \
    echo 'test:' >> config/secrets.yml && \
    echo '  secret_key_base: '$(rake secret) >> config/secrets.yml && \
    echo 'production:' >> config/secrets.yml && \
    echo '  secret_key_base: '$(rake secret) >> config/secrets.yml"

# Configure database
RUN echo "development:" > config/database.yml && \
    echo "  adapter: mysql2" >> config/database.yml && \
    echo "  encoding: utf8" >> config/database.yml && \
    echo "  reconnect: false" >> config/database.yml && \
    echo "  database: $MYSQL_DATABASE" >> config/database.yml && \
    echo "  pool: 5" >> config/database.yml && \
    echo "  username: $MYSQL_USER" >> config/database.yml && \
    echo "  password: $MYSQL_PASSWORD" >> config/database.yml && \
    echo "  host: db" >> config/database.yml && \
    echo "  socket: /var/run/mysqld/mysqld.sock" >> config/database.yml && \
    echo "" >> config/database.yml && \
    echo "production:" >> config/database.yml && \
    echo "  adapter: mysql2" >> config/database.yml && \
    echo "  encoding: utf8" >> config/database.yml && \
    echo "  reconnect: false" >> config/database.yml && \
    echo "  database: $MYSQL_DATABASE" >> config/database.yml && \
    echo "  pool: 5" >> config/database.yml && \
    echo "  username: $MYSQL_USER" >> config/database.yml && \
    echo "  password: $MYSQL_PASSWORD" >> config/database.yml && \
    echo "  host: db" >> config/database.yml && \
    echo "  socket: /var/run/mysqld/mysqld.sock" >> config/database.yml

# Precompile assets
RUN /bin/bash -l -c "source /etc/profile.d/rvm.sh && rvm use ${RUBY_VERSION_WEB} && rake assets:precompile"

# Add and configure scripts
ADD setup.sh /cafe_grader/judge/setup.sh
ADD wait-for-mysql-judge.sh /cafe_grader/wait-for-mysql-judge.sh
ADD wait-for-mysql.sh /cafe_grader/wait-for-mysql.sh

# Make scripts executable
RUN chmod +x /cafe_grader/judge/setup.sh \
    /cafe_grader/wait-for-mysql-judge.sh \
    /cafe_grader/wait-for-mysql.sh

# Update wait-for-mysql-judge.sh script
RUN echo '#!/bin/bash' > /cafe_grader/wait-for-mysql-judge.sh && \
    echo 'source /etc/profile.d/rvm.sh' >> /cafe_grader/wait-for-mysql-judge.sh && \
    echo 'rvm use 2.1.5' >> /cafe_grader/wait-for-mysql-judge.sh && \
    echo 'export BUNDLE_PATH=/cafe_grader/judge/vendor/bundle' >> /cafe_grader/wait-for-mysql-judge.sh && \
    echo 'cd /cafe_grader/judge/scripts' >> /cafe_grader/wait-for-mysql-judge.sh && \
    echo 'echo "Waiting for mysql..."' >> /cafe_grader/wait-for-mysql-judge.sh && \
    echo 'until mysql -h db -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT 1" > /dev/null 2>&1; do' >> /cafe_grader/wait-for-mysql-judge.sh && \
    echo '  echo "Waiting for mysql..."' >> /cafe_grader/wait-for-mysql-judge.sh && \
    echo '  sleep 1' >> /cafe_grader/wait-for-mysql-judge.sh && \
    echo 'done' >> /cafe_grader/wait-for-mysql-judge.sh && \
    echo 'echo "MySQL is ready"' >> /cafe_grader/wait-for-mysql-judge.sh && \
    echo 'bundle _1.17.3_ exec ruby grader grading queue --err-log' >> /cafe_grader/wait-for-mysql-judge.sh

# Fix File.exists? deprecation
RUN find /cafe_grader -type f -name "*.rb" -exec sed -i 's/File\.exists?/File.exist?/g' {} + && \
    find /cafe_grader -type f -name "grader" -exec sed -i 's/File\.exists?/File.exist?/g' {} +

# Set proper permissions for RVM
RUN chmod -R 777 /usr/local/rvm

# Configure RVM in bash
RUN echo 'source /etc/profile.d/rvm.sh' >> /etc/bash.bashrc && \
    echo "rvm use ${RUBY_VERSION_WEB} --default" >> /etc/bash.bashrc

WORKDIR /cafe_grader/web

CMD ["/bin/bash", "-l", "-c", "source /etc/profile.d/rvm.sh && /cafe_grader/wait-for-mysql.sh"]