# frozen_string_literal: true

require 'httparty/logger/apache_formatter'
require 'httparty/logger/curl_formatter'
require 'httparty/logger/logstash_formatter'

module HTTParty
  module Logger
    def self.formatters
      @formatters ||= {
        :curl => Logger::CurlFormatter,
        :apache => Logger::ApacheFormatter,
        :logstash => Logger::LogstashFormatter,
      }
    end

    def self.add_formatter(name, formatter)
      raise HTTParty::Error.new("Log Formatter with name #{name} already exists") if formatters.include?(name)
      formatters.merge!(name.to_sym => formatter)
    end

    def self.build(logger, level, formatter)
      level ||= :info
      formatter ||= :apache

      logger_klass = formatters[formatter] || Logger::ApacheFormatter
      logger_klass.new(logger, level)
    end
  end
end
