# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for places where the `#\_\_dir\_\_` method can replace more
      # complex constructs to retrieve a canonicalized absolute path to the
      # current file.
      #
      # @example
      #   # bad
      #   path = File.expand_path(File.dirname(__FILE__))
      #
      #   # bad
      #   path = File.dirname(File.realpath(__FILE__))
      #
      #   # good
      #   path = __dir__
      class Dir < Base
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.0

        MSG = "Use `__dir__` to get an absolute path to the current file's directory."
        RESTRICT_ON_SEND = %i[expand_path dirname].freeze

        # @!method dir_replacement?(node)
        def_node_matcher :dir_replacement?, <<~PATTERN
          {(send (const {nil? cbase} :File) :expand_path (send (const {nil? cbase} :File) :dirname  #file_keyword?))
           (send (const {nil? cbase} :File) :dirname     (send (const {nil? cbase} :File) :realpath #file_keyword?))}
        PATTERN

        def on_send(node)
          dir_replacement?(node) do
            add_offense(node) do |corrector|
              corrector.replace(node, '__dir__')
            end
          end
        end

        private

        def file_keyword?(node)
          node.str_type? && node.source_range.is?('__FILE__')
        end
      end
    end
  end
end
