# frozen_string_literal: true

require "logger"

##
module MIME
  ##
  class Types
    class << self
      # Configure the MIME::Types logger. This defaults to an instance of a
      # logger that passes messages (unformatted) through to Kernel#warn.
      attr_accessor :logger
    end

    class WarnLogger < ::Logger # :nodoc:
      class WarnLogDevice < ::Logger::LogDevice # :nodoc:
        def initialize(*)
        end

        def write(m)
          Kernel.warn(m)
        end

        def close
        end
      end

      def initialize(_one, _two = nil, _three = nil)
        super nil
        @logdev = WarnLogDevice.new
        @formatter = ->(_s, _d, _p, m) { m }
      end
    end

    self.logger = WarnLogger.new(nil)
  end
end
