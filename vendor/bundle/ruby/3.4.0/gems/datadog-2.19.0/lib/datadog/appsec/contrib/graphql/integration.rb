# frozen_string_literal: true

require_relative '../integration'
require_relative 'patcher'

module Datadog
  module AppSec
    module Contrib
      module GraphQL
        # Description of GraphQL integration
        class Integration
          include Datadog::AppSec::Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('2.0.19')

          AST_NODE_CLASS_NAMES = {
            field: 'GraphQL::Language::Nodes::Field',
            directive: 'GraphQL::Language::Nodes::Directive',
            variable_identifier: 'GraphQL::Language::Nodes::VariableIdentifier',
            input_object: 'GraphQL::Language::Nodes::InputObject',
          }.freeze

          register_as :graphql, auto_patch: false

          def self.version
            Gem.loaded_specs['graphql']&.version
          end

          def self.loaded?
            !defined?(::GraphQL).nil?
          end

          def self.compatible?
            super && version >= MINIMUM_VERSION && ast_node_classes_defined?
          end

          def self.auto_instrument?
            true
          end

          def self.ast_node_classes_defined?
            AST_NODE_CLASS_NAMES.all? do |_, class_name|
              Object.const_defined?(class_name)
            end
          end

          def patcher
            Patcher
          end
        end
      end
    end
  end
end
