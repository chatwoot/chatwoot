module Shoulda
  module Matchers
    # @private
    def self.configure
      yield configuration
    end

    # @private
    def self.integrations
      configuration.integrations
    end

    # @private
    def self.configuration
      @_configuration ||= Configuration.new
    end

    # @private
    class Configuration
      attr_reader :integrations

      def initialize
        @integrations = nil
      end

      def integrate(&block)
        @integrations = Integrations::Configuration.apply(&block)
      end
    end
  end
end
