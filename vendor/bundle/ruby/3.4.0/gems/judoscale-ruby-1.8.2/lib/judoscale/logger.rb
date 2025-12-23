# frozen_string_literal: true

require "judoscale/config"
require "logger"

module Judoscale
  module Logger
    def logger
      if @logger && @logger.log_level == Config.instance.log_level
        @logger
      else
        @logger = LoggerProxy.new(Config.instance.logger, Config.instance.log_level)
      end
    end
  end

  class LoggerProxy < Struct.new(:logger, :log_level)
    %w[ERROR WARN INFO DEBUG FATAL].each do |severity_name|
      severity_level = ::Logger::Severity.const_get(severity_name)

      define_method(severity_name.downcase) do |*messages|
        if log_level.nil?
          logger.public_send(severity_name.downcase) { tag(messages) }
        elsif severity_level >= log_level
          if severity_level >= logger.level
            logger.public_send(severity_name.downcase) { tag(messages) }
          else
            # Our logger proxy is configured with a lower severity level than the underlying logger,
            # so send this message using the underlying logger severity instead of the actual severity.
            logger_severity_name = ::Logger::SEV_LABEL[logger.level].downcase
            logger.public_send(logger_severity_name) { tag(messages, tag_level: severity_name) }
          end
        end
      end
    end

    private

    def tag(msgs, tag_level: nil)
      tag = +"[#{Config.instance.log_tag}]"
      tag << " [#{tag_level}]" if tag_level
      msgs.map { |msg| "#{tag} #{msg}" }.join("\n")
    end
  end
end
