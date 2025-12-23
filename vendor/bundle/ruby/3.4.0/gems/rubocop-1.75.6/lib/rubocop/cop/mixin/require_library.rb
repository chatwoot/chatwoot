# frozen_string_literal: true

module RuboCop
  module Cop
    # Ensure a require statement is present for a standard library determined
    # by variable library_name
    module RequireLibrary
      extend NodePattern::Macros

      RESTRICT_ON_SEND = [:require].freeze

      def ensure_required(corrector, node, library_name)
        node = node.parent while node.parent&.parent?

        if node.parent&.begin_type?
          return if @required_libs.include?(library_name)

          remove_subsequent_requires(corrector, node, library_name)
        end

        RequireLibraryCorrector.correct(corrector, node, library_name)
      end

      def remove_subsequent_requires(corrector, node, library_name)
        node.right_siblings.each do |sibling|
          next unless require_library_name?(sibling, library_name)

          range = range_by_whole_lines(sibling.source_range, include_final_newline: true)
          corrector.remove(range)
        end
      end

      def on_send(node)
        return if node.parent&.parent?

        name = require_any_library?(node)
        return if name.nil?

        @required_libs.add(name)
      end

      private

      def on_new_investigation
        # Holds the required files at top-level
        @required_libs = Set.new
        super
      end

      # @!method require_any_library?(node)
      def_node_matcher :require_any_library?, <<~PATTERN
        (send {(const {nil? cbase} :Kernel) nil?} :require (str $_))
      PATTERN

      # @!method require_library_name?(node, library_name)
      def_node_matcher :require_library_name?, <<~PATTERN
        (send {(const {nil? cbase} :Kernel) nil?} :require (str %1))
      PATTERN
    end
  end
end
