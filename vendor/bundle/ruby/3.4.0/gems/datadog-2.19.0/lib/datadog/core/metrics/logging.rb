# frozen_string_literal: true

require 'logger'
require 'json'

module Datadog
  module Core
    module Metrics
      module Logging
        # Surrogate for Datadog::Statsd to log elsewhere
        class Adapter
          attr_accessor :logger

          def initialize(logger = nil)
            @logger = logger || Logger.new($stdout).tap do |l|
              l.level = ::Logger::INFO
              l.progname = nil
              l.formatter = proc do |_severity, datetime, _progname, msg|
                stat = JSON.parse(msg[3..-1]) # Trim off leading progname...
                "#{JSON.dump(timestamp: datetime.to_i, message: "Metric sent.", metric: stat)}\n"
              end
            end
          end

          def count(stat, value, options = nil)
            logger.info({stat: stat, type: :count, value: value, options: options}.to_json)
          end

          def distribution(stat, value, options = nil)
            logger.info({stat: stat, type: :distribution, value: value, options: options}.to_json)
          end

          def increment(stat, options = nil)
            logger.info({stat: stat, type: :increment, options: options}.to_json)
          end

          def gauge(stat, value, options = nil)
            logger.info({stat: stat, type: :gauge, value: value, options: options}.to_json)
          end
        end
      end
    end
  end
end
