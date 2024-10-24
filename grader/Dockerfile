FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ARG MYSQL_DATABASE
ENV MYSQL_DATABASE $MYSQL_DATABASE
ARG MYSQL_USER
ENV MYSQL_USER $MYSQL_USER
ARG MYSQL_PASSWORD
ENV MYSQL_PASSWORD $MYSQL_PASSWORD

RUN apt-get update && \
    apt-get install -y \
    mysql-client \
    g++ \
    gcc \
    apache2 \
    default-libmysqlclient-dev \
    git-core \
    openssl \
    libreadline-dev \
    zlib1g \
    zlib1g-dev \
    libssl-dev \
    libyaml-dev \
    libsqlite3-dev \
    sqlite3 \
    libxml2-dev \
    libxslt-dev \
    autoconf \
    libc6-dev \
    ncurses-dev \
    automake \
    libtool \
    bison \
    subversion \
    pkg-config \
    unzip \
    python3-pyflakes \
    ruby \
    ruby-dev \
    default-jdk \
    python3-dev \
    python3-setuptools \
    python3-numpy \
    build-essential \
    libpq-dev \
    nodejs \
    curl \
    tzdata && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import -
RUN curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
ENV RUBY_VERSION=3.2.1
ENV TZ=Asia/Bangkok

# Set timezone as root
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create a non-root user for running Bundler
RUN useradd -m -s /bin/bash grader
RUN mkdir -p /cafe_grader && chown -R grader:grader /cafe_grader

# Switch to non-root user for RVM installation
USER grader
RUN curl -k -L https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "source $HOME/.rvm/scripts/rvm && \
    rvm install $RUBY_VERSION && \
    rvm use $RUBY_VERSION --default"

# Install correct Bundler version
RUN /bin/bash -l -c "gem install bundler:2.3.22"

USER root
RUN mkdir -p /cafe_grader/judge
WORKDIR /cafe_grader/judge
ADD scripts /cafe_grader/judge/scripts
RUN mkdir raw ev-exam ev result log && \
    chown -R grader:grader /cafe_grader

# Configuration files
RUN cp scripts/config/env_exam.rb.SAMPLE scripts/config/env_exam.rb && \
    cp scripts/config/env_grading.rb.SAMPLE scripts/config/env_grading.rb

RUN echo "RAILS_ROOT = '/cafe_grader/web'" > scripts/config/environment.rb && \
    echo "GRADER_ROOT = '/cafe_grader/judge/scripts'" >> scripts/config/environment.rb && \
    echo "require File.join(File.dirname(__FILE__),'../lib/boot')" >> scripts/config/environment.rb && \
    echo "require File.dirname(__FILE__) + \"/env_#{GRADER_ENV}.rb\"" >> scripts/config/environment.rb

RUN gcc -std=c99 -o scripts/std-script/box scripts/std-script/box64-new.c

# Web setup
WORKDIR /cafe_grader
ADD web /cafe_grader/web
COPY worker.yml /cafe_grader/web/config/worker.yml
RUN cp web/config/application.rb.SAMPLE web/config/application.rb && \
    cp web/config/initializers/cafe_grader_config.rb.SAMPLE web/config/initializers/cafe_grader_config.rb

RUN export timezone=`cat /etc/timezone` && \
    sed -i "s!'UTC'!'$timezone'!g" web/config/application.rb

WORKDIR /cafe_grader/web

# Update grader configuration
RUN echo "Object.instance_eval{remove_const :GRADER_ROOT_DIR}" >> config/initializers/cafe_grader_config.rb && \
    echo "Object.instance_eval{remove_const :GRADING_RESULT_DIR}" >> config/initializers/cafe_grader_config.rb && \
    echo "GRADER_ROOT_DIR = '/cafe_grader/judge'" >> config/initializers/cafe_grader_config.rb && \
    echo "GRADING_RESULT_DIR = '/cafe_grader/judge/result'" >> config/initializers/cafe_grader_config.rb

# Switch to non-root user for bundle install
USER grader
RUN /bin/bash -l -c "cd /cafe_grader/web && bundle install"

# Database setup
RUN /bin/bash -l -c "cd /cafe_grader/web && \
    echo 'development:' > config/secrets.yml && \
    echo '  secret_key_base: '$(rake secret) >> config/secrets.yml && \
    echo 'test:' >> config/secrets.yml && \
    echo '  secret_key_base: '$(rake secret) >> config/secrets.yml && \
    echo 'production:' >> config/secrets.yml && \
    echo '  secret_key_base: '$(rake secret) >> config/secrets.yml"

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

RUN /bin/bash -l -c "cd /cafe_grader/web && rake assets:precompile"

WORKDIR /cafe_grader/web
ADD setup.sh /cafe_grader/judge/setup.sh
ADD wait-for-mysql-judge.sh /cafe_grader/wait-for-mysql-judge.sh
ADD wait-for-mysql.sh /cafe_grader/wait-for-mysql.sh

USER root
CMD ["/bin/bash", "/cafe_grader/wait-for-mysql.sh"]