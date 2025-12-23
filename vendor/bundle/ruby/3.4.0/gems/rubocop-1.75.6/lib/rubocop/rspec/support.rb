# frozen_string_literal: true

# Require this file to load code that supports testing using RSpec.

require_relative 'cop_helper'
require_relative 'expect_offense'
require_relative 'parallel_formatter'
require_relative 'shared_contexts'

RSpec.configure do |config|
  config.include CopHelper
  config.include RuboCop::RSpec::ExpectOffense
  config.include_context 'config', :config
  config.include_context 'isolated environment', :isolated_environment
  config.include_context 'isolated bundler', :isolated_bundler
  config.include_context 'lsp', :lsp
  config.include_context 'maintain registry', :restore_registry
  config.include_context 'maintain default configuration', :restore_configuration
  config.include_context 'mock obsoletion', :mock_obsoletion
  config.include_context 'ruby 2.0', :ruby20
  config.include_context 'ruby 2.1', :ruby21
  config.include_context 'ruby 2.2', :ruby22
  config.include_context 'ruby 2.3', :ruby23
  config.include_context 'ruby 2.4', :ruby24
  config.include_context 'ruby 2.5', :ruby25
  config.include_context 'ruby 2.6', :ruby26
  config.include_context 'ruby 2.7', :ruby27
  config.include_context 'ruby 3.0', :ruby30
  config.include_context 'ruby 3.1', :ruby31
  config.include_context 'ruby 3.2', :ruby32
  config.include_context 'ruby 3.3', :ruby33
  config.include_context 'ruby 3.4', :ruby34
  config.include_context 'ruby 3.5', :ruby35
end
