# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for the use of `YAML.load`, `YAML.safe_load`, and `YAML.parse` with
      # `File.read` argument.
      #
      # NOTE: `YAML.safe_load_file` was introduced in Ruby 3.0.
      #
      # @example
      #
      #   # bad
      #   YAML.load(File.read(path))
      #   YAML.parse(File.read(path))
      #
      #   # good
      #   YAML.load_file(path)
      #   YAML.parse_file(path)
      #
      #   # bad
      #   YAML.safe_load(File.read(path)) # Ruby 3.0 and newer
      #
      #   # good
      #   YAML.safe_load_file(path)       # Ruby 3.0 and newer
      #
      class YAMLFileRead < Base
        extend AutoCorrector

        MSG = 'Use `%<prefer>s` instead.'
        RESTRICT_ON_SEND = %i[load safe_load parse].freeze

        # @!method yaml_file_read?(node)
        def_node_matcher :yaml_file_read?, <<~PATTERN
          (send
            (const {cbase nil?} :YAML) _
            (send
              (const {cbase nil?} :File) :read $_) $...)
        PATTERN

        def on_send(node)
          return if node.method?(:safe_load) && target_ruby_version <= 2.7
          return unless (file_path, rest_arguments = yaml_file_read?(node))

          range = offense_range(node)
          rest_arguments = if rest_arguments.empty?
                             ''
                           else
                             ", #{rest_arguments.map(&:source).join(', ')}"
                           end
          prefer = "#{node.method_name}_file(#{file_path.source}#{rest_arguments})"

          add_offense(range, message: format(MSG, prefer: prefer)) do |corrector|
            corrector.replace(range, prefer)
          end
        end

        private

        def offense_range(node)
          node.loc.selector.join(node.source_range.end)
        end
      end
    end
  end
end
