# frozen_string_literal: true

module Datadog
  module Core
    # A {Datadog::Core::Pin} sets metadata on a particular object.
    #
    # This is useful if you want the object to reflect
    # customized behavior or attributes, like an eigenclass.
    class Pin
      def self.get_from(obj)
        return nil unless obj.respond_to? :datadog_pin

        obj.datadog_pin
      end

      def self.set_on(obj, **options)
        if (pin = get_from(obj))
          options.each { |k, v| pin[k] = v }
        else
          pin = new(**options)
          pin.onto(obj)
        end

        pin
      end

      def initialize(**options)
        @options = options
      end

      def [](name)
        @options[name]
      end

      def []=(name, value)
        @options[name] = value
      end

      def key?(name)
        @options.key?(name)
      end

      # rubocop:disable Style/TrivialAccessors
      def onto(obj)
        unless obj.respond_to? :datadog_pin=
          obj.instance_exec do
            def datadog_pin=(pin)
              @datadog_pin = pin
            end
          end
        end

        unless obj.respond_to? :datadog_pin
          obj.instance_exec do
            def datadog_pin
              @datadog_pin
            end
          end
        end

        obj.datadog_pin = self
      end
      # rubocop:enable Style/TrivialAccessors

      def to_s
        pretty_options = options.to_a.map { |k, v| "#{k}:#{v}" }.join(', ')
        "Pin(#{pretty_options})"
      end

      private

      attr_accessor :options
    end
  end
end
