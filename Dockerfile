FROM ruby:3.4

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install

COPY . .

ENV RACK_ENV=production
ENV PORT=80
EXPOSE 80

# Once platform: persistent storage and backup/restore hooks
RUN mkdir -p /storage/log
COPY once/hooks/ /hooks/
RUN chmod +x /hooks/*

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
