# frozen_string_literal: true

module Sentry
  class Breadcrumb
    DATA_SERIALIZATION_ERROR_MESSAGE = "[data were removed due to serialization issues]"

    # @return [String, nil]
    attr_accessor :category
    # @return [Hash, nil]
    attr_accessor :data
    # @return [String, nil]
    attr_reader :level
    # @return [Time, Integer, nil]
    attr_accessor :timestamp
    # @return [String, nil]
    attr_accessor :type
    # @return [String, nil]
    attr_reader :message

    # @param category [String, nil]
    # @param data [Hash, nil]
    # @param message [String, nil]
    # @param timestamp [Time, Integer, nil]
    # @param level [String, nil]
    # @param type [String, nil]
    def initialize(category: nil, data: nil, message: nil, timestamp: nil, level: nil, type: nil)
      @category = category
      @data = data || {}
      @timestamp = timestamp || Sentry.utc_now.to_i
      @type = type
      self.message = message
      self.level = level
    end

    # @return [Hash]
    def to_hash
      {
        category: @category,
        data: serialized_data,
        level: @level,
        message: @message,
        timestamp: @timestamp,
        type: @type
      }
    end

    # @param message [String]
    # @return [void]
    def message=(message)
      @message = (message || "").byteslice(0..Event::MAX_MESSAGE_SIZE_IN_BYTES)
    end

    # @param level [String]
    # @return [void]
    def level=(level) # needed to meet the Sentry spec
      @level = level == "warn" ? "warning" : level
    end

    private

    def serialized_data
      begin
        ::JSON.parse(::JSON.generate(@data))
      rescue Exception => e
        Sentry.logger.debug(LOGGER_PROGNAME) do
          <<~MSG
can't serialize breadcrumb data because of error: #{e}
data: #{@data}
          MSG
        end

        DATA_SERIALIZATION_ERROR_MESSAGE
      end
    end
  end
end
