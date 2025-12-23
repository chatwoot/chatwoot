# frozen_string_literal: true

module Dry
  module Configurable
    class Extension < Module
      # @api private
      attr_reader :config_class

      # @api private
      attr_reader :default_undefined

      # @api private
      def initialize(config_class: Configurable::Config, default_undefined: false)
        super()
        @config_class = config_class
        @default_undefined = default_undefined
        freeze
      end

      # @api private
      def extended(klass)
        super
        klass.extend(ClassMethods)
        klass.instance_variable_set(:@__config_extension__, self)
      end

      # @api private
      def included(klass)
        super

        klass.class_eval do
          extend(ClassMethods)
          include(InstanceMethods)
          prepend(Initializer)

          class << self
            undef :config if method_defined?(:config)
            undef :configure if method_defined?(:configure)
          end
        end

        klass.instance_variable_set(:@__config_extension__, self)
      end
    end
  end
end
