# Enabling Logging

To enable logging for this library, set the logger for the underlying [Google
API
Client](https://github.com/google/google-api-ruby-client/blob/master/README.md#logging)
library. The logger that you set may be a Ruby stdlib
[`Logger`](https://ruby-doc.org/stdlib-2.4.0/libdoc/logger/rdoc/Logger.html) as
shown below, or a
[`Google::Cloud::Logging::Logger`](https://googleapis.dev/ruby/google-cloud-logging/latest)
that will write logs to [Stackdriver
Logging](https://cloud.google.com/logging/).

If you do not set the logger explicitly and your application is running in a
Rails environment, it will default to `Rails.logger`. Otherwise, if you do not
set the logger and you are not using Rails, logging is disabled by default.

Configuring a Ruby stdlib logger:

```ruby
require "logger"

my_logger = Logger.new $stderr
my_logger.level = Logger::WARN

# Set the Google API Client logger
Google::Apis.logger = my_logger
```
