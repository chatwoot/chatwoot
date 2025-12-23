# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Looks for references to a cop configuration key that isn't defined in config/default.yml.
      class UndefinedConfig < Base
        # `FileFinder` is a private API not intended to be used by cops,
        # but it's fine for `InternalAffairs`.
        extend FileFinder

        ALLOWED_CONFIGURATIONS = %w[
          Safe SafeAutoCorrect AutoCorrect
          Severity
          StyleGuide
          Details
          Reference References
          Include Exclude
        ].freeze
        RESTRICT_ON_SEND = %i[[] fetch].freeze
        MSG = '`%<name>s` is not defined in the configuration for `%<cop>s` ' \
              'in `config/default.yml`.'
        CONFIG_PATH = find_file_upwards('config/default.yml', Dir.pwd)
        CONFIG = if CONFIG_PATH
                   begin
                     original_debug = ConfigLoader.debug
                     ConfigLoader.debug = false
                     ConfigLoader.load_yaml_configuration(CONFIG_PATH)
                   ensure
                     ConfigLoader.debug = original_debug
                   end
                 else
                   {}
                 end

        # @!method cop_class_def(node)
        def_node_search :cop_class_def, <<~PATTERN
          (class _
            (const {nil? (const nil? :Cop) (const (const {cbase nil?} :RuboCop) :Cop)}
              {:Base :Cop}) ...)
        PATTERN

        # @!method cop_config_accessor?(node)
        def_node_matcher :cop_config_accessor?, <<~PATTERN
          (send (send nil? :cop_config) {:[] :fetch} ${str sym}...)
        PATTERN

        def on_new_investigation
          super
          return unless processed_source.ast

          cop_class = cop_class_def(processed_source.ast).first
          return unless (@cop_class_name = extract_cop_name(cop_class))

          @config_for_cop = CONFIG[@cop_class_name] || {}
        end

        def on_send(node)
          return unless cop_class_name
          return unless (config_name_node = cop_config_accessor?(node))
          return if always_allowed?(config_name_node)
          return if configuration_key_defined?(config_name_node)

          message = format(MSG, name: config_name_node.value, cop: cop_class_name)
          add_offense(config_name_node, message: message)
        end

        private

        attr_reader :config_for_cop, :cop_class_name

        def extract_cop_name(class_node)
          return unless class_node

          segments = [class_node].concat(
            class_node.each_ancestor(:class, :module).take_while do |n|
              n.identifier.short_name != :Cop
            end
          )

          segments.reverse_each.map { |s| s.identifier.short_name }.join('/')
        end

        def always_allowed?(node)
          ALLOWED_CONFIGURATIONS.include?(node.value)
        end

        def configuration_key_defined?(node)
          config_for_cop.key?(node.value)
        end
      end
    end
  end
end
