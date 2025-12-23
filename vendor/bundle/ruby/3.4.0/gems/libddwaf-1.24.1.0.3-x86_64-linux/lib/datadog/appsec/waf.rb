# frozen_string_literal: true

require "datadog/appsec/waf/lib_ddwaf"

require "datadog/appsec/waf/handle_builder"
require "datadog/appsec/waf/handle"
require "datadog/appsec/waf/converter"
require "datadog/appsec/waf/errors"
require "datadog/appsec/waf/result"
require "datadog/appsec/waf/context"
require "datadog/appsec/waf/version"

module Datadog
  module AppSec
    module WAF
      module_function

      def version
        LibDDWAF.ddwaf_get_version
      end

      def log_callback(level, func, file, line, message, len)
        return if WAF.logger.nil?

        WAF.logger.debug do
          {
            level: level,
            func: func,
            file: file,
            line: line,
            message: message.read_bytes(len)
          }.inspect
        end
      end

      def logger
        @logger
      end

      def logger=(logger)
        unless @log_callback
          log_callback = WAF.method(:log_callback)
          LibDDWAF.ddwaf_set_log_cb(log_callback, :ddwaf_log_trace)

          # retain logging proc if set properly
          @log_callback = log_callback
        end

        @logger = logger
      end
    end
  end
end
