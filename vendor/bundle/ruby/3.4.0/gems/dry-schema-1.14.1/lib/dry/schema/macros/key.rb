# frozen_string_literal: true

module Dry
  module Schema
    module Macros
      # Base macro for specifying rules applied to a value found under a key
      #
      # @api public
      class Key < DSL
        # @!attribute [r] filter_schema_dsl
        #   @return [Schema::DSL]
        #   @api private
        option :filter_schema_dsl, default: proc { schema_dsl&.filter_schema_dsl }

        # Specify predicates that should be applied before coercion
        #
        # @example check format before coercing to a date
        #   required(:publish_date).filter(format?: /\d{4}-\d{2}-\d{2}).value(:date)
        #
        # @see Macros::Key#value
        #
        # @return [Macros::Key]
        #
        # @api public
        def filter(...)
          (filter_schema_dsl[name] || filter_schema_dsl.optional(name)).value(...)
          self
        end

        # Coerce macro to a rule
        #
        # @return [Dry::Logic::Rule]
        #
        # @api private
        def to_rule
          if trace.captures.empty?
            super
          else
            [super, trace.to_rule(name)].reduce(operation)
          end
        end

        # @api private
        def to_ast
          [:predicate, [:key?, [[:name, name], [:input, Undefined]]]]
        end
      end
    end
  end
end
