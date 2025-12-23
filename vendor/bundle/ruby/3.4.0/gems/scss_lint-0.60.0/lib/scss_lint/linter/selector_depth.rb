module SCSSLint
  # Checks for selectors with large depths of applicability.
  class Linter::SelectorDepth < Linter
    include LinterRegistry

    def visit_root(_node)
      @max_depth = config['max_depth']
      @depth = 0
      yield # Continue
    end

    def visit_rule(node)
      old_depth = @depth
      @depth = max_sequence_depth(node.parsed_rules, @depth)

      if @depth > @max_depth
        add_lint(node.parsed_rules || node,
                 'Selector should have depth of applicability no greater ' \
                 "than #{@max_depth}, but was #{@depth}")
      end

      yield # Continue linting children
      @depth = old_depth
    end

  private

    # Find the maximum depth of all sequences in a comma sequence.
    def max_sequence_depth(comma_sequence, current_depth)
      # Sequence contains interpolation; assume a depth of 1
      return current_depth + 1 unless comma_sequence

      comma_sequence.members.map { |sequence| sequence_depth(sequence, current_depth) }.max
    end

    def sequence_depth(sequence, current_depth)
      separators, simple_sequences = sequence.members.partition do |item|
        item.is_a?(String)
      end

      parent_selectors = simple_sequences.count do |item|
        next if item.is_a?(Array) # @keyframe percentages end up as Arrays
        item.rest.any? { |i| i.is_a?(Sass::Selector::Parent) }
      end

      # Take the number of simple sequences and subtract one for each sibling
      # combinator, as these "combine" simple sequences such that they do not
      # increase depth.
      depth = simple_sequences.size -
        separators.count { |item| %w[~ +].include?(item) }

      depth +=
        if parent_selectors > 0
          # If parent selectors are present, add the current depth for each
          # additional parent selector.
          parent_selectors * (current_depth - 1)
        else
          # Otherwise this just descends from the containing selector
          current_depth
        end

      depth
    end
  end
end
