# sentry-sidekiq example

## Usage

1. run `bundle install`
2. change the `dsn` inside `error_worker.rb`
3. run `bundle exec sidekiq -r ./error_worker.rb`
4. you should see the event from your Sentry dashboard
