# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for use of the `File.expand_path` arguments.
      # Likewise, it also checks for the `Pathname.new` argument.
      #
      # Contrastive bad case and good case are alternately shown in
      # the following examples.
      #
      # @example
      #   # bad
      #   File.expand_path('..', __FILE__)
      #
      #   # good
      #   File.expand_path(__dir__)
      #
      #   # bad
      #   File.expand_path('../..', __FILE__)
      #
      #   # good
      #   File.expand_path('..', __dir__)
      #
      #   # bad
      #   File.expand_path('.', __FILE__)
      #
      #   # good
      #   File.expand_path(__FILE__)
      #
      #   # bad
      #   Pathname(__FILE__).parent.expand_path
      #
      #   # good
      #   Pathname(__dir__).expand_path
      #
      #   # bad
      #   Pathname.new(__FILE__).parent.expand_path
      #
      #   # good
      #   Pathname.new(__dir__).expand_path
      #
      class ExpandPathArguments < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `expand_path(%<new_path>s%<new_default_dir>s)` instead of ' \
              '`expand_path(%<current_path>s, __FILE__)`.'
        PATHNAME_MSG = 'Use `Pathname(__dir__).expand_path` instead of ' \
                       '`Pathname(__FILE__).parent.expand_path`.'
        PATHNAME_NEW_MSG = 'Use `Pathname.new(__dir__).expand_path` ' \
                           'instead of ' \
                           '`Pathname.new(__FILE__).parent.expand_path`.'

        RESTRICT_ON_SEND = %i[expand_path].freeze

        # @!method file_expand_path(node)
        def_node_matcher :file_expand_path, <<~PATTERN
          (send
            (const {nil? cbase} :File) :expand_path
            $_
            $_)
        PATTERN

        # @!method pathname_parent_expand_path(node)
        def_node_matcher :pathname_parent_expand_path, <<~PATTERN
          (send
            (send
              (send nil? :Pathname
                $_) :parent) :expand_path)
        PATTERN

        # @!method pathname_new_parent_expand_path(node)
        def_node_matcher :pathname_new_parent_expand_path, <<~PATTERN
          (send
            (send
              (send
                (const {nil? cbase} :Pathname) :new
                $_) :parent) :expand_path)
        PATTERN

        def on_send(node)
          if (current_path, default_dir = file_expand_path(node))
            inspect_offense_for_expand_path(node, current_path, default_dir)
          elsif (default_dir = pathname_parent_expand_path(node))
            return unless unrecommended_argument?(default_dir)

            add_offense(node, message: PATHNAME_MSG) { |corrector| autocorrect(corrector, node) }
          elsif (default_dir = pathname_new_parent_expand_path(node))
            return unless unrecommended_argument?(default_dir)

            add_offense(node, message: PATHNAME_NEW_MSG) do |corrector|
              autocorrect(corrector, node)
            end
          end
        end

        private

        def autocorrect(corrector, node)
          if (current_path, default_dir = file_expand_path(node))
            autocorrect_expand_path(corrector, current_path, default_dir)
          elsif (dir = pathname_parent_expand_path(node) || pathname_new_parent_expand_path(node))
            corrector.replace(dir, '__dir__')
            remove_parent_method(corrector, dir)
          end
        end

        def unrecommended_argument?(default_dir)
          default_dir.source == '__FILE__'
        end

        def inspect_offense_for_expand_path(node, current_path, default_dir)
          return unless unrecommended_argument?(default_dir) && current_path.str_type?

          current_path = strip_surrounded_quotes!(current_path.source)

          parent_path = parent_path(current_path)
          new_path = parent_path == '' ? '' : "'#{parent_path}', "

          new_default_dir = depth(current_path).zero? ? '__FILE__' : '__dir__'

          message = format(
            MSG,
            new_path: new_path,
            new_default_dir: new_default_dir,
            current_path: "'#{current_path}'"
          )

          add_offense(node.loc.selector, message: message) do |corrector|
            autocorrect(corrector, node)
          end
        end

        def autocorrect_expand_path(corrector, current_path, default_dir)
          stripped_current_path = strip_surrounded_quotes!(current_path.source)

          case depth(stripped_current_path)
          when 0
            range = arguments_range(current_path.parent)

            corrector.replace(range, '__FILE__')
          when 1
            range = arguments_range(current_path.parent)

            corrector.replace(range, '__dir__')
          else
            new_path = "'#{parent_path(stripped_current_path)}'"

            corrector.replace(current_path, new_path)
            corrector.replace(default_dir, '__dir__')
          end
        end

        def strip_surrounded_quotes!(path_string)
          path_string.slice!(path_string.length - 1)
          path_string.slice!(0)

          path_string
        end

        def depth(current_path)
          paths = current_path.split(File::SEPARATOR)

          paths.count { |path| path != '.' }
        end

        def parent_path(current_path)
          paths = current_path.split(File::SEPARATOR)

          paths.delete('.')
          paths.each_with_index do |path, index|
            if path == '..'
              paths.delete_at(index)
              break
            end
          end

          paths.join(File::SEPARATOR)
        end

        def remove_parent_method(corrector, default_dir)
          node = default_dir.parent.parent.parent.children.first

          corrector.remove(node.loc.dot)
          corrector.remove(node.loc.selector)
        end
      end
    end
  end
end
