# frozen_string_literal: true

require 'rubocop'

require_relative 'rubocop/performance'
require_relative 'rubocop/performance/version'
require_relative 'rubocop/performance/plugin'
require_relative 'rubocop/cop/performance_cops'

RuboCop::Cop::Lint::UnusedMethodArgument.singleton_class.prepend(
  Module.new do
    def autocorrect_incompatible_with
      super.push(RuboCop::Cop::Performance::BlockGivenWithExplicitBlock)
    end
  end
)
