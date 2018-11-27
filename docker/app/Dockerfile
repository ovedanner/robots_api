FROM ruby:2.5.3

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

ENV RAILS_ROOT /var/www/robots

RUN mkdir -p $RAILS_ROOT

WORKDIR $RAILS_ROOT

ENV RAILS_ENV='production'
ENV RACK_ENV='production'

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN bundle install --jobs 20 --retry 5 --without development test

COPY . .
EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
