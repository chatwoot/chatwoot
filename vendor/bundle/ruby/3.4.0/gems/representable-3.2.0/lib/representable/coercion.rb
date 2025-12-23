gem 'dry-types', '>= 1.0.0'
require "dry-types"

module Representable
  module Coercion
    module Types
      include Dry::Types()
    end
    class Coercer
      def initialize(type)
        @type = type
      end

      def call(input, _options)
        @type.call(input)
      end
    end


    def self.included(base)
      base.class_eval do
        extend ClassMethods
        register_feature Coercion
      end
    end


    module ClassMethods
      def property(name, options={}, &block)
        super.tap do |definition|
          return definition unless type = options[:type]

          definition.merge!(render_filter: coercer = Coercer.new(type))
          definition.merge!(parse_filter: coercer)
        end
      end
    end
  end
end
