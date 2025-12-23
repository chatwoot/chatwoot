# frozen_string_literal: true

module SCSSLint
  # Checks for unnecessary uses of the parent reference (&) in nested selectors.
  class Linter::UnnecessaryParentReference < Linter
    include LinterRegistry

    MESSAGE = 'Unnecessary parent selector (&)'.freeze

    def visit_comma_sequence(comma_sequence)
      @multiple_sequences = comma_sequence.members.size > 1
    end

    def visit_sequence(sequence)
      return unless sequence_starts_with_parent?(sequence.members.first)

      # Allow concatentation, e.g.
      # element {
      #   &.foo {}
      # }
      return if sequence.members.first.members.size > 1

      # Allow sequences that contain multiple parent references, e.g.
      # element {
      #   & + & { ... }
      # }
      return if sequence.members[1..-1].any? { |ss| sequence_contains_parent_reference?(ss) }

      # Special case: allow an isolated parent to appear if it is part of a
      # comma sequence of more than one sequence, as this could be used to DRY
      # up code.
      return if @multiple_sequences && isolated_parent?(sequence)

      add_lint(sequence.members.first.line, MESSAGE)
    end

  private

    def isolated_parent?(sequence)
      sequence.members.size == 1 &&
        sequence_starts_with_parent?(sequence.members.first)
    end

    def sequence_starts_with_parent?(simple_sequence)
      return unless simple_sequence.is_a?(Sass::Selector::SimpleSequence)
      first = simple_sequence.members.first
      first.is_a?(Sass::Selector::Parent) &&
        first.suffix.nil? # Ignore concatenated selectors, like `&-something`
    end

    def sequence_contains_parent_reference?(simple_sequence)
      return unless simple_sequence.is_a?(Sass::Selector::SimpleSequence)
      simple_sequence.members.any? { |s| s.is_a?(Sass::Selector::Parent) }
    end
  end
end
