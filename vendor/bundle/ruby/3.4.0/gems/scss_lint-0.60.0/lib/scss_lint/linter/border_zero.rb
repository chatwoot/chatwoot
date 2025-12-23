module SCSSLint
  # Enforce a particular value for empty borders.
  class Linter::BorderZero < Linter
    include LinterRegistry

    CONVENTION_TO_PREFERENCE = {
      'zero' => %w[0 none],
      'none' => %w[none 0],
    }.freeze

    BORDER_PROPERTIES = %w[
      border
      border-top
      border-right
      border-bottom
      border-left
    ].freeze

    def visit_root(_node)
      @preference = CONVENTION_TO_PREFERENCE[config['convention'].to_s]
      unless @preference
        raise "Invalid `convention` specified: #{config['convention']}." \
              "Must be one of [#{CONVENTION_TO_PREFERENCE.keys.join(', ')}]"
      end
      yield # Continue linting children
    end

    def visit_prop(node)
      return unless BORDER_PROPERTIES.include?(node.name.first.to_s)
      check_border(node, node.name.first.to_s, node.value.first.to_sass.strip)
    end

  private

    def check_border(node, border_property, border_value)
      return unless %w[0 none].include?(border_value)
      return if @preference[0] == border_value

      add_lint(node, "`#{border_property}: #{@preference[0]}` is preferred over " \
                     "`#{border_property}: #{@preference[1]}`")
    end
  end
end
