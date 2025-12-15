FROM ruby:3.3.6

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  nodejs \
  postgresql-client

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

ENV RAILS_ENV=production
RUN bundle exec rails assets:precompile

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
