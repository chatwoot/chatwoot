# frozen_string_literal: true

module Dry
  # Helper methods for constraint types
  #
  # @api public
  module Types
    # @param [Hash] options
    #
    # @return [Dry::Logic::Rule]
    #
    # @api public
    def self.Rule(options)
      rule_compiler.(
        options.map { |key, val|
          ::Dry::Logic::Rule::Predicate.build(
            ::Dry::Logic::Predicates[:"#{key}?"]
          ).curry(val).to_ast
        }
      ).reduce(:and)
    end

    # @return [Dry::Logic::RuleCompiler]
    #
    # @api private
    def self.rule_compiler
      @rule_compiler ||= ::Dry::Logic::RuleCompiler.new(::Dry::Logic::Predicates)
    end
  end
end
