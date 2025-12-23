# frozen_string_literal: true

require "dry/initializer"
require "dry/schema/constants"

module Dry
  module Schema
    # Applies rules defined within the DSL
    #
    # @api private
    class RuleApplier
      extend ::Dry::Initializer

      # @api private
      param :rules

      # @api private
      option :config, default: -> { Schema.config.dup }

      # @api private
      option :message_compiler, default: -> { MessageCompiler.new(Messages.setup(config.messages)) }

      # @api private
      def call(input)
        results = EMPTY_ARRAY.dup

        rules.each do |name, rule|
          next if input.error?(name)

          result = rule.(input.to_h)
          results << result if result.failure?
        end

        input.concat(results)
      end

      # @api private
      def to_ast
        if config.messages.namespace
          [:namespace, [config.messages.namespace, [:set, rules.values.map(&:to_ast)]]]
        else
          [:set, rules.values.map(&:to_ast)]
        end
      end
    end
  end
end
