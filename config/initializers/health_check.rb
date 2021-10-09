## gem reference https://github.com/ianheggie/health_check

HealthCheck.setup do |config|
  # uri prefix (no leading slash)
  config.uri = 'health_check'

  # Text output upon success
  config.success = 'success'

  # Text output upon failure
  config.failure = 'health_check failed'

  # Disable the error message to prevent /health_check from leaking
  # sensitive information
  config.include_error_in_response_body = false

  # Log level (success or failure message with error details is sent to rails log unless this is set to nil)
  config.log_level = 'info'

  # Timeout in seconds used when checking smtp server
  config.smtp_timeout = 30.0

  # http status code used when plain text error message is output
  # Set to 200 if you want your want to distinguish between partial (text does not include success) and
  # total failure of rails application (http status of 500 etc)

  config.http_status_for_error_text = 500

  # http status code used when an error object is output (json or xml)
  # Set to 200 if you want to distinguish between partial (healthy property == false) and
  # total failure of rails application (http status of 500 etc)

  config.http_status_for_error_object = 500

  # bucket names to test connectivity - required only if s3 check used, access permissions can be mixed
  #   config.buckets = { 'bucket_name' => [:R, :W, :D] }

  # You can customize which checks happen on a standard health check, eg to set an explicit list use:
  config.standard_checks = %w[database migrations custom]

  # Or to exclude one check:
  config.standard_checks -= ['emailconf']

  # You can set what tests are run with the 'full' or 'all' parameter
  config.full_checks = %w[database migrations custom email cache redis sidekiq-redis]

  # Add one or more custom checks that return a blank string if ok, or an error message if there is an error
  #   config.add_custom_check do
  #     CustomHealthCheck.perform_check # any code that returns blank on success and non blank string upon failure
  #   end

  # Add another custom check with a name, so you can call just specific custom checks. This can also be run using
  # the standard 'custom' check.
  # You can define multiple tests under the same name - they will be run one after the other.
  #   config.add_custom_check('sometest') do
  #     CustomHealthCheck.perform_another_check # any code that returns blank on success and non blank string upon failure
  #   end

  # max-age of response in seconds
  # cache-control is public when max_age > 1 and basic_auth_username is not set
  # You can force private without authentication for longer max_age by
  # setting basic_auth_username but not basic_auth_password
  config.max_age = 1

  # Protect health endpoints with basic auth
  # These default to nil and the endpoint is not protected
  #   config.basic_auth_username = 'my_username'
  #   config.basic_auth_password = 'my_password'

  # rubocop:disable Naming/InclusiveLanguage

  # Whitelist requesting IPs by a list of IP and/or CIDR ranges, either IPv4 or IPv6 (uses IPAddr.include? method to check)
  # Defaults to blank which allows any IP
  #   config.origin_ip_whitelist = %w[123.123.123.123 10.11.12.0/24 2400:cb00::/32]

  # Use ActionDispatch::Request's remote_ip method when behind a proxy to pick up the real remote IP for origin_ip_whitelist check
  # Otherwise uses Rack::Request's ip method (the default, and always used by Middleware), which is more susceptable to spoofing
  # See https://stackoverflow.com/questions/10997005/whats-the-difference-between-request-remote-ip-and-request-ip-in-rails
  config.accept_proxied_requests = false

  # http status code used when the ip is not allowed for the request
  config.http_status_for_ip_whitelist_error = 403
  # rubocop:enable Naming/InclusiveLanguage

  # rabbitmq
  # config.rabbitmq_config = {}

  # # When redis url/password is non-standard
  # config.redis_url = 'redis_url' # default ENV['REDIS_URL']
  # # Only included if set, as url can optionally include passwords as well
  # config.redis_password = 'redis_password' # default ENV['REDIS_PASSWORD']

  # Failure Hooks to do something more ...
  # checks lists the checks requested
  #   config.on_failure do |checks, msg|
  #     # log msg somewhere
  #   end

  #   config.on_success do |checks|
  #     # flag that everything is well
  #   end
end
