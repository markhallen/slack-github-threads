FROM ruby:3.2

WORKDIR /app
COPY . .

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev
RUN gem install bundler && bundle install

ENV RACK_ENV=production
CMD ["bundle", "exec", "thin", "start", "-R", "config.ru", "-p", "3000"]
