require "logtail"

http_io_device = Logtail::LogDevices::HTTP.new(
  ENV.fetch("SOURCE_TOKEN"),
  ingesting_host: ENV.fetch("INGESTING_HOST"),
)
LOGTAIL_LOGGER = Logtail::Logger.new(http_io_device) unless defined?(LOGTAIL_LOGGER)