# frozen_string_literal: true

require 'rubocop'
require 'rack/utils'
require 'active_support/inflector'

require_relative 'rubocop/rails'
require_relative 'rubocop/rails/version'
require_relative 'rubocop/rails/schema_loader'
require_relative 'rubocop/rails/schema_loader/schema'
require_relative 'rubocop/rails/plugin'
require_relative 'rubocop/cop/rails_cops'

require_relative 'rubocop/rails/migration_file_skippable'
RuboCop::Rails::MigrationFileSkippable.apply_to_cops!

RuboCop::Cop::Style::HashExcept.minimum_target_ruby_version(2.0)

RuboCop::Cop::Style::InverseMethods.singleton_class.prepend(
  Module.new do
    def autocorrect_incompatible_with
      super.push(RuboCop::Cop::Rails::NegateInclude)
    end
  end
)

RuboCop::Cop::Style::MethodCallWithArgsParentheses.singleton_class.prepend(
  Module.new do
    def autocorrect_incompatible_with
      super.push(RuboCop::Cop::Rails::EagerEvaluationLogMessage)
    end
  end
)

RuboCop::Cop::Style::RedundantSelf.singleton_class.prepend(
  Module.new do
    def autocorrect_incompatible_with
      super.push(RuboCop::Cop::Rails::SafeNavigation)
    end
  end
)
