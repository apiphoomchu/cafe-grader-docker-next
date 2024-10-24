FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ARG MYSQL_DATABASE
ENV MYSQL_DATABASE $MYSQL_DATABASE
ARG MYSQL_USER
ENV MYSQL_USER $MYSQL_USER
ARG MYSQL_PASSWORD
ENV MYSQL_PASSWORD $MYSQL_PASSWORD
RUN apt-get update && \
	apt-get install mysql-client -y \
	g++ gcc apache2 libmysqlclient20 \
	git-core openssl libreadline6 libreadline6-dev \
	zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev \
	sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev \
	ncurses-dev automake libtool bison subversion \
	pkg-config unzip pyflakes ruby ruby-dev default-jdk \
	libmysqld-dev mercurial python-setuptools python-dev python3-numpy \
	build-essential libpq-dev nodejs curl tzdata && rm -rf /var/lib/apt/lists/*
WORKDIR /
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import -
RUN curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
ENV RUBY_VERSION=3.2.1
ENV TZ=Asia/Bangkok
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN curl -k -L https://get.rvm.io | bash -s stable
RUN /bin/bash /etc/profile.d/rvm.sh
RUN /bin/bash -l -c "rvm install $RUBY_VERSION"
RUN /bin/bash -l -c "rvm use $RUBY_VERSION"
RUN mkdir cafe_grader

# Judge
RUN mkdir /cafe_grader/judge
WORKDIR /cafe_grader/judge
ADD scripts /cafe_grader/judge/scripts
RUN mkdir raw
RUN mkdir ev-exam
RUN mkdir ev
RUN mkdir result
RUN mkdir log

RUN cp scripts/config/env_exam.rb.SAMPLE scripts/config/env_exam.rb
RUN cp scripts/config/env_grading.rb.SAMPLE scripts/config/env_grading.rb

RUN echo "RAILS_ROOT = '/cafe_grader/web'" > scripts/config/environment.rb
RUN echo "GRADER_ROOT = '/cafe_grader/judge/scripts'" >> scripts/config/environment.rb
RUN echo "require File.join(File.dirname(__FILE__),'../lib/boot')" >> scripts/config/environment.rb
RUN echo "require File.dirname(__FILE__) + \"/env_#{GRADER_ENV}.rb\"" >> scripts/config/environment.rb

RUN gcc -std=c99 -o scripts/std-script/box scripts/std-script/box64-new.c

# Web
WORKDIR /cafe_grader
ADD web /cafe_grader/web
RUN cp web/config/application.rb.SAMPLE web/config/application.rb
COPY worker.yml /cafe_grader/web/config/worker.yml
RUN cp web/config/initializers/cafe_grader_config.rb.SAMPLE web/config/initializers/cafe_grader_config.rb
RUN export timezone=`cat /etc/timezone` && export replace="s!'UTC'!'$timezone'!g" && sed -i $replace web/config/application.rb
WORKDIR /cafe_grader/web

RUN echo "Object.instance_eval{remove_const :GRADER_ROOT_DIR}" >> config/initializers/cafe_grader_config.rb 
RUN echo "Object.instance_eval{remove_const :GRADING_RESULT_DIR}" >> config/initializers/cafe_grader_config.rb
RUN echo "GRADER_ROOT_DIR = '/cafe_grader/judge'" >> config/initializers/cafe_grader_config.rb
RUN echo "GRADING_RESULT_DIR = '/cafe_grader/judge/result'" >> config/initializers/cafe_grader_config.rb

# Setup Rails environment
RUN /bin/bash -l -c "gem install rails -v '~> 7.0'"
RUN /bin/bash -l -c "bundle config set --local path 'vendor/bundle'"
RUN /bin/bash -l -c "bundle config set --local without 'development test'"
RUN /bin/bash -l -c "bundle install"

# Install Node.js dependencies for Rails asset compilation
RUN npm install -g yarn
RUN yarn install

# Create necessary directories
RUN mkdir -p tmp/cache
RUN mkdir -p public/assets
RUN chmod -R 777 tmp
RUN chmod -R 777 public
RUN mkdir -p app/assets/builds

# Create custom CSS to override problematic styles
RUN mkdir -p app/assets/stylesheets/custom
RUN echo '/* Custom overrides */' > app/assets/stylesheets/custom/overrides.css
RUN echo '.dt-row-selected { background-color: #e6e6e6 !important; }' >> app/assets/stylesheets/custom/overrides.css
RUN echo '[class*="flex-"] { display: flex !important; }' >> app/assets/stylesheets/custom/overrides.css

# Database setup
RUN echo "development:" > config/secrets.yml
RUN export SECRET_A=`/bin/bash -l -c "rake secret"` && echo "  secret_key_base: '$SECRET_A'" >> config/secrets.yml
RUN echo "test:" >> config/secrets.yml
RUN export SECRET_B=`/bin/bash -l -c "rake secret"` && echo "  secret_key_base: '$SECRET_B'" >> config/secrets.yml
RUN echo "production:" >> config/secrets.yml
RUN export SECRET_C=`/bin/bash -l -c "rake secret"` && echo "  secret_key_base: '$SECRET_C'" >> config/secrets.yml

# Database configuration
RUN echo "development:" > config/database.yml
RUN echo "  adapter: mysql2" >> config/database.yml
RUN echo "  encoding: utf8mb4" >> config/database.yml
RUN echo "  reconnect: false" >> config/database.yml
RUN echo "  database: $MYSQL_DATABASE" >> config/database.yml
RUN echo "  pool: 5" >> config/database.yml
RUN echo "  username: $MYSQL_USER" >> config/database.yml
RUN echo "  password: $MYSQL_PASSWORD" >> config/database.yml
RUN echo "  host: db" >> config/database.yml
RUN echo "  socket: /var/run/mysqld/mysqld.sock" >> config/database.yml
RUN echo "" >> config/database.yml
RUN echo "production:" >> config/database.yml
RUN echo "  adapter: mysql2" >> config/database.yml
RUN echo "  encoding: utf8mb4" >> config/database.yml
RUN echo "  reconnect: false" >> config/database.yml
RUN echo "  database: $MYSQL_DATABASE" >> config/database.yml
RUN echo "  pool: 5" >> config/database.yml
RUN echo "  username: $MYSQL_USER" >> config/database.yml
RUN echo "  password: $MYSQL_PASSWORD" >> config/database.yml
RUN echo "  host: db" >> config/database.yml
RUN echo "  socket: /var/run/mysqld/mysqld.sock" >> config/database.yml

WORKDIR /cafe_grader/web
ADD setup.sh /cafe_grader/judge/setup.sh
ADD wait-for-mysql-judge.sh /cafe_grader/wait-for-mysql-judge.sh
ADD wait-for-mysql.sh /cafe_grader/wait-for-mysql.sh

# Create a new entrypoint script
RUN echo '#!/bin/bash' > /cafe_grader/entrypoint.sh
RUN echo 'cd /cafe_grader/web' >> /cafe_grader/entrypoint.sh
RUN echo 'RAILS_ENV=production bundle exec rake assets:precompile || true' >> /cafe_grader/entrypoint.sh
RUN echo 'exec /bin/bash /cafe_grader/wait-for-mysql.sh' >> /cafe_grader/entrypoint.sh
RUN chmod +x /cafe_grader/entrypoint.sh

CMD ["/cafe_grader/entrypoint.sh"]