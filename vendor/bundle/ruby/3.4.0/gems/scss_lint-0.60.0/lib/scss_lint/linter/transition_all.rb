module SCSSLint
  # Checks for explicitly transitioned properties instead of transition all.
  class Linter::TransitionAll < Linter
    include LinterRegistry

    TRANSITION_PROPERTIES = %w[
      transition
      transition-property
    ].freeze

    def visit_prop(node)
      property = node.name.first.to_s
      return unless TRANSITION_PROPERTIES.include?(property)

      check_transition(node, property, node.value.first.to_sass)
    end

  private

    def check_transition(node, property, value)
      return unless offset = value =~ /\ball\b/

      pos = node.value_source_range.start_pos.after(value[0, offset])

      add_lint(Location.new(pos.line, pos.offset, 3),
               "#{property} should contain explicit properties " \
                'instead of using the keyword all')
    end
  end
end
