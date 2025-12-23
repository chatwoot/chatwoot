# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Identifies usages of file path joining process to use `Rails.root.join` clause.
      # It is used to add uniformity when joining paths.
      #
      # NOTE: This cop ignores leading slashes in string literal arguments for `Rails.root.join`
      #       and multiple slashes in string literal arguments for `Rails.root.join` and `File.join`.
      #
      # @example EnforcedStyle: slashes (default)
      #   # bad
      #   Rails.root.join('app', 'models', 'goober')
      #
      #   # good
      #   Rails.root.join('app/models/goober')
      #
      #   # bad
      #   File.join(Rails.root, 'app/models/goober')
      #   "#{Rails.root}/app/models/goober"
      #
      #   # good
      #   Rails.root.join('app/models/goober').to_s
      #
      # @example EnforcedStyle: arguments
      #   # bad
      #   Rails.root.join('app/models/goober')
      #
      #   # good
      #   Rails.root.join('app', 'models', 'goober')
      #
      #   # bad
      #   File.join(Rails.root, 'app/models/goober')
      #   "#{Rails.root}/app/models/goober"
      #
      #   # good
      #   Rails.root.join('app', 'models', 'goober').to_s
      #
      class FilePath < Base
        extend AutoCorrector

        include ConfigurableEnforcedStyle
        include RangeHelp

        MSG_SLASHES = 'Prefer `Rails.root.join(\'path/to\')%<to_s>s`.'
        MSG_ARGUMENTS = 'Prefer `Rails.root.join(\'path\', \'to\')%<to_s>s`.'
        RESTRICT_ON_SEND = %i[join].freeze

        def_node_matcher :file_join_nodes?, <<~PATTERN
          (send (const {nil? cbase} :File) :join ...)
        PATTERN

        def_node_search :rails_root_nodes?, <<~PATTERN
          (send (const {nil? cbase} :Rails) :root)
        PATTERN

        def_node_matcher :rails_root_join_nodes?, <<~PATTERN
          (send #rails_root_nodes? :join ...)
        PATTERN

        def on_dstr(node)
          return unless rails_root_nodes?(node)
          return if dstr_separated_by_colon?(node)

          check_for_slash_after_rails_root_in_dstr(node)
          check_for_extension_after_rails_root_join_in_dstr(node)
        end

        def on_send(node)
          check_for_file_join_with_rails_root(node)
          return unless node.receiver

          check_for_rails_root_join_with_slash_separated_path(node)
          check_for_rails_root_join_with_string_arguments(node)
        end

        private

        def check_for_slash_after_rails_root_in_dstr(node)
          rails_root_index = find_rails_root_index(node)
          slash_node = node.children[rails_root_index + 1]
          return unless slash_node&.str_type? && slash_node.source.start_with?(File::SEPARATOR)
          return unless node.children[rails_root_index].children.first.send_type?

          register_offense(node, require_to_s: false) do |corrector|
            autocorrect_slash_after_rails_root_in_dstr(corrector, node, rails_root_index)
          end
        end

        def check_for_extension_after_rails_root_join_in_dstr(node)
          rails_root_index = find_rails_root_index(node)
          extension_node = node.children[rails_root_index + 1]
          return unless extension_node?(extension_node)

          register_offense(node, require_to_s: false) do |corrector|
            autocorrect_extension_after_rails_root_join_in_dstr(corrector, node, rails_root_index, extension_node)
          end
        end

        def check_for_file_join_with_rails_root(node)
          return unless file_join_nodes?(node)
          return unless valid_arguments_for_file_join_with_rails_root?(node.arguments)

          register_offense(node, require_to_s: true) do |corrector|
            autocorrect_file_join(corrector, node) unless node.first_argument.array_type?
          end
        end

        def check_for_rails_root_join_with_string_arguments(node)
          return unless style == :slashes
          return unless rails_root_nodes?(node)
          return unless rails_root_join_nodes?(node)
          return unless valid_string_arguments_for_rails_root_join?(node.arguments)

          register_offense(node, require_to_s: false) do |corrector|
            autocorrect_rails_root_join_with_string_arguments(corrector, node)
          end
        end

        def check_for_rails_root_join_with_slash_separated_path(node)
          return unless style == :arguments
          return unless rails_root_nodes?(node)
          return unless rails_root_join_nodes?(node)
          return unless valid_slash_separated_path_for_rails_root_join?(node.arguments)

          register_offense(node, require_to_s: false) do |corrector|
            autocorrect_rails_root_join_with_slash_separated_path(corrector, node)
          end
        end

        def valid_arguments_for_file_join_with_rails_root?(arguments)
          return false unless arguments.any? { |arg| rails_root_nodes?(arg) }

          arguments.none? { |arg| arg.variable? || arg.const_type? || string_contains_multiple_slashes?(arg) }
        end

        def valid_string_arguments_for_rails_root_join?(arguments)
          return false unless arguments.size > 1
          return false unless arguments.all?(&:str_type?)

          arguments.none? { |arg| string_with_leading_slash?(arg) || string_contains_multiple_slashes?(arg) }
        end

        def valid_slash_separated_path_for_rails_root_join?(arguments)
          return false unless arguments.any? { |arg| string_contains_slash?(arg) }

          arguments.none? { |arg| string_with_leading_slash?(arg) || string_contains_multiple_slashes?(arg) }
        end

        def string_contains_slash?(node)
          node.str_type? && node.value.include?(File::SEPARATOR)
        end

        def string_contains_multiple_slashes?(node)
          node.str_type? && node.value.include?('//')
        end

        def string_with_leading_slash?(node)
          node.str_type? && node.value.start_with?(File::SEPARATOR)
        end

        def register_offense(node, require_to_s:, &block)
          line_range = node.loc.column...node.loc.last_column
          source_range = source_range(processed_source.buffer, node.first_line, line_range)

          message = build_message(require_to_s)

          add_offense(source_range, message: message, &block)
        end

        def build_message(require_to_s)
          message_template = style == :arguments ? MSG_ARGUMENTS : MSG_SLASHES
          to_s = require_to_s ? '.to_s' : ''

          format(message_template, to_s: to_s)
        end

        def dstr_separated_by_colon?(node)
          node.children[1..].any? do |child|
            child.str_type? && child.source.start_with?(':')
          end
        end

        def autocorrect_slash_after_rails_root_in_dstr(corrector, node, rails_root_index)
          rails_root_node = node.children[rails_root_index].children.first
          argument_source = extract_rails_root_join_argument_source(node, rails_root_index)
          if rails_root_node.method?(:join)
            append_argument(corrector, rails_root_node, argument_source)
          else
            replace_with_rails_root_join(corrector, rails_root_node, argument_source)
          end
          node.children[rails_root_index + 1..].each { |child| corrector.remove(child) }
        end

        def autocorrect_extension_after_rails_root_join_in_dstr(corrector, node, rails_root_index, extension_node)
          rails_root_node = node.children[rails_root_index].children.first
          return unless rails_root_node.last_argument.str_type?

          corrector.insert_before(rails_root_node.last_argument.location.end, extension_node.source)
          corrector.remove(extension_node)
        end

        def autocorrect_file_join(corrector, node)
          replace_receiver_with_rails_root(corrector, node)
          remove_first_argument_with_comma(corrector, node)
          process_arguments(corrector, node.arguments)
          append_to_string_conversion(corrector, node)
        end

        def replace_receiver_with_rails_root(corrector, node)
          corrector.replace(node.receiver, 'Rails.root')
        end

        def remove_first_argument_with_comma(corrector, node)
          corrector.remove(
            range_with_surrounding_space(
              range_with_surrounding_comma(
                node.first_argument.source_range,
                :right
              ),
              side: :right
            )
          )
        end

        def process_arguments(corrector, arguments)
          arguments.each do |argument|
            if argument.str_type?
              corrector.replace(argument, argument.value.delete_prefix('/').inspect)
            elsif argument.array_type?
              corrector.replace(argument, "*#{argument.source}")
            end
          end
        end

        def append_to_string_conversion(corrector, node)
          corrector.insert_after(node, '.to_s')
        end

        def autocorrect_rails_root_join_with_string_arguments(corrector, node)
          corrector.replace(node.first_argument, %("#{node.arguments.map(&:value).join('/')}"))
          node.arguments[1..].each do |argument|
            corrector.remove(
              range_with_surrounding_comma(
                range_with_surrounding_space(
                  argument.source_range,
                  side: :left
                ),
                :left
              )
            )
          end
        end

        def autocorrect_rails_root_join_with_slash_separated_path(corrector, node)
          node.arguments.each do |argument|
            next unless string_contains_slash?(argument)

            index = argument.source.index(File::SEPARATOR)
            rest = inner_range_of(argument).adjust(begin_pos: index - 1)
            corrector.remove(rest)
            corrector.insert_after(argument, %(, "#{rest.source.delete_prefix(File::SEPARATOR)}"))
          end
        end

        def inner_range_of(node)
          node.location.end.with(begin_pos: node.location.begin.end_pos).adjust(end_pos: -1)
        end

        def find_rails_root_index(node)
          node.children.index { |child| rails_root_nodes?(child) }
        end

        def append_argument(corrector, node, argument_source)
          corrector.insert_after(node.last_argument, %(, "#{argument_source}"))
        end

        def replace_with_rails_root_join(corrector, node, argument_source)
          corrector.replace(node, %<Rails.root.join("#{argument_source}")>)
        end

        def extract_rails_root_join_argument_source(node, rails_root_index)
          node.children[rails_root_index + 1..].map(&:source).join.delete_prefix(File::SEPARATOR)
        end

        def extension_node?(node)
          node&.str_type? && node.source.match?(/\A\.[A-Za-z]+/)
        end
      end
    end
  end
end
