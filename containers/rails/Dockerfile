FROM ruby:2.7.1-buster

ENV DEBCONF_NOWARNINGS yes
ENV TZ 'Asia/Tokyo'
ENV LANG C.UTF-8
ENV RAILS_LOG_TO_STDOUT 1
ENV RAILS_ENV "development"

RUN apt-get update
RUN apt-get install -y build-essential default-mysql-client

ENV APP_ROOT /app
WORKDIR $APP_ROOT

ADD Gemfile $APP_ROOT
ADD Gemfile.lock $APP_ROOT

RUN bundle install

ADD . $APP_ROOT
