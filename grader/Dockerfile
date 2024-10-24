FROM ubuntu:16.04
ENV DEBIAN_FRONTEND=noninteractive
ARG MYSQL_DATABASE
ENV MYSQL_DATABASE $MYSQL_DATABASE
ARG MYSQL_USER
ENV MYSQL_USER $MYSQL_USER
ARG MYSQL_PASSWORD
ENV MYSQL_PASSWORD $MYSQL_PASSWORD
ENV RAILS_ENV=development
ENV GRADER_ENV=grading

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

# Install RVM and Ruby
RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && \
    curl -sSL https://get.rvm.io | bash -s stable && \
    /bin/bash -l -c " \
    source /usr/local/rvm/scripts/rvm && \
    rvm install 3.2.1 && \
    rvm use 3.2.1 --default && \
    rvm rubygems latest && \
    gem update --system && \
    gem install bundler:2.4.22"

# Setup directory structure
RUN mkdir -p /cafe_grader/{judge,web} \
    /cafe_grader/judge/{raw,ev-exam,ev,result,log,scripts} \
    /usr/local/bundle && \
    chmod -R 777 /cafe_grader /usr/local/bundle

# Add application files
WORKDIR /cafe_grader
ADD scripts /cafe_grader/judge/scripts
ADD web /cafe_grader/web
COPY worker.yml /cafe_grader/web/config/worker.yml

# Configure judge
WORKDIR /cafe_grader/judge
RUN cp scripts/config/env_exam.rb.SAMPLE scripts/config/env_exam.rb && \
    cp scripts/config/env_grading.rb.SAMPLE scripts/config/env_grading.rb && \
    echo "RAILS_ROOT = '/cafe_grader/web'" > scripts/config/environment.rb && \
    echo "GRADER_ROOT = '/cafe_grader/judge/scripts'" >> scripts/config/environment.rb && \
    echo "require File.join(File.dirname(__FILE__),'../lib/boot')" >> scripts/config/environment.rb && \
    echo "require File.dirname(__FILE__) + '/env_grading.rb'" >> scripts/config/environment.rb

# Compile grader box
RUN gcc -std=c99 -o scripts/std-script/box scripts/std-script/box64-new.c

# Configure web application
WORKDIR /cafe_grader/web
RUN cp config/application.rb.SAMPLE config/application.rb && \
    cp config/initializers/cafe_grader_config.rb.SAMPLE config/initializers/cafe_grader_config.rb && \
    sed -i "s!'UTC'!'${TZ}'!g" config/application.rb

# Update grader configuration
RUN echo "GRADER_ROOT_DIR = '/cafe_grader/judge'" > config/initializers/cafe_grader_config.rb && \
    echo "GRADING_RESULT_DIR = '/cafe_grader/judge/result'" >> config/initializers/cafe_grader_config.rb

# Create database configuration
RUN echo "default: &default" > config/database.yml && \
    echo "  adapter: mysql2" >> config/database.yml && \
    echo "  encoding: utf8" >> config/database.yml && \
    echo "  reconnect: false" >> config/database.yml && \
    echo "  pool: 5" >> config/database.yml && \
    echo "  username: ${MYSQL_USER}" >> config/database.yml && \
    echo "  password: ${MYSQL_PASSWORD}" >> config/database.yml && \
    echo "  host: db" >> config/database.yml && \
    echo "  socket: /var/run/mysqld/mysqld.sock" >> config/database.yml && \
    echo "" >> config/database.yml && \
    echo "development:" >> config/database.yml && \
    echo "  <<: *default" >> config/database.yml && \
    echo "  database: ${MYSQL_DATABASE}" >> config/database.yml && \
    echo "" >> config/database.yml && \
    echo "production:" >> config/database.yml && \
    echo "  <<: *default" >> config/database.yml && \
    echo "  database: ${MYSQL_DATABASE}" >> config/database.yml

# Create secrets configuration
RUN /bin/bash -l -c " \
    source /usr/local/rvm/scripts/rvm && \
    rvm use 3.2.1 && \
    echo 'development:' > config/secrets.yml && \
    echo '  secret_key_base: '$(rake secret) >> config/secrets.yml && \
    echo 'production:' >> config/secrets.yml && \
    echo '  secret_key_base: '$(rake secret) >> config/secrets.yml"

# Install gems for web application
WORKDIR /cafe_grader/web
RUN /bin/bash -l -c " \
    source /usr/local/rvm/scripts/rvm && \
    rvm use 3.2.1 && \
    bundle config set --local path '/usr/local/bundle' && \
    bundle install --jobs 4 --retry 3"

# Install gems for judge if needed
WORKDIR /cafe_grader/judge/scripts
RUN /bin/bash -l -c " \
    source /usr/local/rvm/scripts/rvm && \
    rvm use 3.2.1 && \
    if [ -f Gemfile ]; then \
        bundle config set --local path '/usr/local/bundle' && \
        bundle install --jobs 4 --retry 3; \
    fi"

# Create initializer for GraderProcess
RUN mkdir -p /cafe_grader/web/config/initializers && \
    echo 'class GraderProcess' > /cafe_grader/web/config/initializers/grader_process_patch.rb && \
    echo '  class << self' >> /cafe_grader/web/config/initializers/grader_process_patch.rb && \
    echo '    alias_method :register, :register_grader if method_defined?(:register_grader)' >> /cafe_grader/web/config/initializers/grader_process_patch.rb && \
    echo '  end' >> /cafe_grader/web/config/initializers/grader_process_patch.rb && \
    echo 'end' >> /cafe_grader/web/config/initializers/grader_process_patch.rb

# Add and configure scripts
ADD setup.sh /cafe_grader/judge/setup.sh
ADD wait-for-mysql-judge.sh /cafe_grader/wait-for-mysql-judge.sh
ADD wait-for-mysql.sh /cafe_grader/wait-for-mysql.sh
RUN chmod +x /cafe_grader/judge/setup.sh \
    /cafe_grader/wait-for-mysql-judge.sh \
    /cafe_grader/wait-for-mysql.sh

# Fix deprecation warnings
RUN find /cafe_grader -type f -name "*.rb" -exec sed -i 's/File\.exists?/File.exist?/g' {} + && \
    find /cafe_grader -type f -name "grader" -exec sed -i 's/File\.exists?/File.exist?/g' {} +

# Ensure proper permissions
RUN chmod -R 777 /usr/local/rvm /cafe_grader

# Configure shell environment
RUN echo 'source /usr/local/rvm/scripts/rvm' >> /etc/bash.bashrc && \
    echo 'rvm use 3.2.1 --default' >> /etc/bash.bashrc

WORKDIR /cafe_grader/web

# Create a wrapper script for the main command
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'source /usr/local/rvm/scripts/rvm' >> /entrypoint.sh && \
    echo 'rvm use 3.2.1' >> /entrypoint.sh && \
    echo 'cd /cafe_grader/web' >> /entrypoint.sh && \
    echo 'bundle exec rails runner "puts Rails.env"' >> /entrypoint.sh && \
    echo 'exec /cafe_grader/wait-for-mysql.sh' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]