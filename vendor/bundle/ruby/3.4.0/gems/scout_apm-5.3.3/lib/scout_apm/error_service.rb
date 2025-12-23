require "net/http"
require "net/https"
require "uri"

module ScoutApm
  module ErrorService
    API_VERSION = "1"

    HEADERS = {
      "Content-type" => "application/json",
      "Accept" => "application/json"
    }

    # Public API to force a given exception to be captured.
    # Still obeys the ignore list
    # Used internally by SidekiqException
    def self.capture(exception, params = {})
      return if disabled?

      context = ScoutApm::Agent.instance.context
      return if context.ignored_exceptions.ignore?(exception)

      context.errors_buffer.capture(exception, env)
    end

    def self.enabled?
      ScoutApm::Agent.instance.context.config.value("errors_enabled")
    end

    def self.disabled?
      !enabled?
    end
  end
end
