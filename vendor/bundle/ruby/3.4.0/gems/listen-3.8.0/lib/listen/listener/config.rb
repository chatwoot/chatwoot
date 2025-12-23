# frozen_string_literal: true

module Listen
  class Listener
    class Config
      DEFAULTS = {
        # Listener options
        debug: false, # TODO: is this broken?
        wait_for_delay: nil, # NOTE: should be provided by adapter if possible
        relative: false,

        # Backend selecting options
        force_polling: false,
        polling_fallback_message: nil
      }.freeze

      def initialize(opts)
        @options = DEFAULTS.merge(opts)
        @relative = @options[:relative]
        @min_delay_between_events = @options[:wait_for_delay]
        @silencer_rules = @options # silencer will extract what it needs
      end

      def relative?
        @relative
      end

      attr_reader :min_delay_between_events, :silencer_rules

      def adapter_instance_options(klass)
        valid_keys = klass.const_get('DEFAULTS').keys
        Hash[@options.select { |key, _| valid_keys.include?(key) }]
      end

      def adapter_select_options
        valid_keys = %w[force_polling polling_fallback_message].map(&:to_sym)
        Hash[@options.select { |key, _| valid_keys.include?(key) }]
      end
    end
  end
end
