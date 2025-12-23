# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Favor `File.(bin)read` convenience methods.
      #
      # @example
      #   # bad - text mode
      #   File.open(filename).read
      #   File.open(filename, &:read)
      #   File.open(filename) { |f| f.read }
      #   File.open(filename) do |f|
      #     f.read
      #   end
      #   File.open(filename, 'r').read
      #   File.open(filename, 'r', &:read)
      #   File.open(filename, 'r') do |f|
      #     f.read
      #   end
      #
      #   # good
      #   File.read(filename)
      #
      #   # bad - binary mode
      #   File.open(filename, 'rb').read
      #   File.open(filename, 'rb', &:read)
      #   File.open(filename, 'rb') do |f|
      #     f.read
      #   end
      #
      #   # good
      #   File.binread(filename)
      #
      class FileRead < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Use `File.%<read_method>s`.'

        RESTRICT_ON_SEND = %i[open].freeze

        READ_FILE_START_TO_FINISH_MODES = %w[r rt rb r+ r+t r+b].to_set.freeze

        # @!method file_open?(node)
        def_node_matcher :file_open?, <<~PATTERN
          (send
            (const {nil? cbase} :File)
            :open
            $_
            (str $%READ_FILE_START_TO_FINISH_MODES)?
            $(block-pass (sym :read))?
          )
        PATTERN

        # @!method send_read?(node)
        def_node_matcher :send_read?, <<~PATTERN
          (send _ :read)
        PATTERN

        # @!method block_read?(node)
        def_node_matcher :block_read?, <<~PATTERN
          (block _ (args (arg _name)) (send (lvar _name) :read))
        PATTERN

        def on_send(node)
          evidence(node) do |filename, mode, read_node|
            message = format(MSG, read_method: read_method(mode))

            add_offense(read_node, message: message) do |corrector|
              range = range_between(node.loc.selector.begin_pos, read_node.source_range.end_pos)
              replacement = "#{read_method(mode)}(#{filename.source})"

              corrector.replace(range, replacement)
            end
          end
        end

        private

        def evidence(node)
          file_open?(node) do |filename, mode_array, block_pass|
            read_node?(node, block_pass) do |read_node|
              yield(filename, mode_array.first || 'r', read_node)
            end
          end
        end

        def read_node?(node, block_pass)
          if block_pass.any?
            yield(node)
          elsif file_open_read?(node.parent)
            yield(node.parent)
          end
        end

        def file_open_read?(node)
          return true if send_read?(node)

          block_read?(node)
        end

        def read_method(mode)
          mode.end_with?('b') ? :binread : :read
        end
      end
    end
  end
end
