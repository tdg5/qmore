#FROM ruby:2.7.8-bullseye
FROM ruby:3.3.0-bullseye
#FROM ruby:3.3.0-bullseye

RUN apt-get update && apt-get install -y libxml2-dev redis-tools vim

WORKDIR /app

ENV OPENSSL_CONF=/etc/ssl/

COPY Gemfile qmore.gemspec .
COPY lib/qmore/version.rb lib/qmore/version.rb

RUN  git config --global --add safe.directory /app

RUN NOKOGIRI_USE_SYSTEM_LIBRARIES=1 bundle install
RUN bundle install

CMD bundle exec rake
