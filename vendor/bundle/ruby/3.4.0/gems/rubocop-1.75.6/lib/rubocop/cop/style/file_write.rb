# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Favor `File.(bin)write` convenience methods.
      #
      # NOTE: There are different method signatures between `File.write` (class method)
      # and `File#write` (instance method). The following case will be allowed because
      # static analysis does not know the contents of the splat argument:
      #
      # [source,ruby]
      # ----
      # File.open(filename, 'w') do |f|
      #   f.write(*objects)
      # end
      # ----
      #
      # @example
      #   # bad - text mode
      #   File.open(filename, 'w').write(content)
      #   File.open(filename, 'w') do |f|
      #     f.write(content)
      #   end
      #
      #   # good
      #   File.write(filename, content)
      #
      #   # bad - binary mode
      #   File.open(filename, 'wb').write(content)
      #   File.open(filename, 'wb') do |f|
      #     f.write(content)
      #   end
      #
      #   # good
      #   File.binwrite(filename, content)
      #
      class FileWrite < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Use `File.%<write_method>s`.'

        RESTRICT_ON_SEND = %i[open].to_set.freeze

        TRUNCATING_WRITE_MODES = %w[w wt wb w+ w+t w+b].to_set.freeze

        # @!method file_open?(node)
        def_node_matcher :file_open?, <<~PATTERN
          (send
            (const {nil? cbase} :File)
            :open
            $_
            (str $%TRUNCATING_WRITE_MODES)
            (block-pass (sym :write))?
          )
        PATTERN

        # @!method send_write?(node)
        def_node_matcher :send_write?, <<~PATTERN
          (send _ :write $_)
        PATTERN

        # @!method block_write?(node)
        def_node_matcher :block_write?, <<~PATTERN
          (block _ (args (arg $_)) (send (lvar $_) :write $_))
        PATTERN

        def on_send(node)
          evidence(node) do |filename, mode, content, write_node|
            message = format(MSG, write_method: write_method(mode))

            add_offense(write_node, message: message) do |corrector|
              range = range_between(node.loc.selector.begin_pos, write_node.source_range.end_pos)
              replacement = replacement(mode, filename, content, write_node)

              corrector.replace(range, replacement)
            end
          end
        end

        def evidence(node)
          file_open?(node) do |filename, mode|
            file_open_write?(node.parent) do |content|
              yield(filename, mode, content, node.parent)
            end
          end
        end

        private

        def file_open_write?(node)
          content = send_write?(node) || block_write?(node) do |block_arg, lvar, write_arg|
            write_arg if block_arg == lvar
          end
          return false if content&.splat_type?

          yield(content) if content
        end

        def write_method(mode)
          mode.end_with?('b') ? :binwrite : :write
        end

        def replacement(mode, filename, content, write_node)
          replacement = "#{write_method(mode)}(#{filename.source}, #{content.source})"

          if heredoc?(write_node)
            first_argument = write_node.body.first_argument

            <<~REPLACEMENT.chomp
              #{replacement}
              #{heredoc_range(first_argument).source}
            REPLACEMENT
          else
            replacement
          end
        end

        def heredoc?(write_node)
          write_node.block_type? && (first_argument = write_node.body.first_argument) &&
            first_argument.respond_to?(:heredoc?) && first_argument.heredoc?
        end

        def heredoc_range(first_argument)
          range_between(
            first_argument.loc.heredoc_body.begin_pos, first_argument.loc.heredoc_end.end_pos
          )
        end
      end
    end
  end
end
