# frozen_string_literal: true

module Dry
  module Logic
    module Operations
      class Abstract
        include Core::Constants
        include ::Dry::Equalizer(:rules, :options)
        include Operators

        attr_reader :rules

        attr_reader :options

        def initialize(*rules, **options)
          @rules = rules
          @options = options
        end

        def id
          options[:id]
        end

        def curry(*args)
          new(rules.map { |rule| rule.curry(*args) }, **options)
        end

        def new(rules, **new_options)
          self.class.new(*rules, **options, **new_options)
        end

        def with(new_options)
          new(rules, **options, **new_options)
        end

        def to_ast
          ast
        end
      end
    end
  end
end
