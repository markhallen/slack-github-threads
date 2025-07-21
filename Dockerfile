FROM ruby:3.2

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install

COPY . .

ENV RACK_ENV=production
ENV PORT=80
EXPOSE 80

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
