# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Prefer to use `File.empty?('path/to/file')` when checking if a file is empty.
      #
      # @safety
      #   This cop is unsafe, because `File.size`, `File.read`, and `File.binread`
      #   raise `ENOENT` exception when there is no file corresponding to the path,
      #   while `File.empty?` does not raise an exception.
      #
      # @example
      #   # bad
      #   File.zero?('path/to/file')
      #   File.size('path/to/file') == 0
      #   File.size('path/to/file') >= 0
      #   File.size('path/to/file').zero?
      #   File.read('path/to/file').empty?
      #   File.binread('path/to/file') == ''
      #   FileTest.zero?('path/to/file')
      #
      #   # good
      #   File.empty?('path/to/file')
      #   FileTest.empty?('path/to/file')
      #
      class FileEmpty < Base
        extend AutoCorrector
        extend TargetRubyVersion

        MSG = 'Use `%<file_class>s.empty?(%<arg>s)` instead.'
        RESTRICT_ON_SEND = %i[>= != == zero? empty?].freeze

        minimum_target_ruby_version 2.4

        # @!method offensive?(node)
        def_node_matcher :offensive?, <<~PATTERN
          {
            (send $(const {nil? cbase} {:File :FileTest}) :zero? $_)
            (send (send $(const {nil? cbase} {:File :FileTest}) :size $_) {:== :>=} (int 0))
            (send (send (send $(const {nil? cbase} {:File :FileTest}) :size $_) :!) {:== :>=} (int 0))
            (send (send $(const {nil? cbase} {:File :FileTest}) :size $_) :zero?)
            (send (send $(const {nil? cbase} {:File :FileTest}) {:read :binread} $_) {:!= :==} (str empty?))
            (send (send (send $(const {nil? cbase} {:File :FileTest}) {:read :binread} $_) :!) {:!= :==} (str empty?))
            (send (send $(const {nil? cbase} {:File :FileTest}) {:read :binread} $_) :empty?)
          }
        PATTERN

        def on_send(node)
          offensive?(node) do |const_node, arg_node|
            add_offense(node,
                        message: format(MSG, file_class: const_node.source,
                                             arg: arg_node.source)) do |corrector|
              corrector.replace(node,
                                "#{bang(node)}#{const_node.source}.empty?(#{arg_node.source})")
            end
          end
        end

        private

        def bang(node)
          if (node.method?(:==) && node.child_nodes.first.method?(:!)) ||
             (%i[>= !=].include?(node.method_name) && !node.child_nodes.first.method?(:!))
            '!'
          end
        end
      end
    end
  end
end
