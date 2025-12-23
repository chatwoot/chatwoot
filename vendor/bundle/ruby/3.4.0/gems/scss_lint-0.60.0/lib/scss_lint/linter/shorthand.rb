module SCSSLint
  # Checks for the use of the shortest form for properties that can be written
  # in shorthand.
  class Linter::Shorthand < Linter
    include LinterRegistry

    def visit_root(*)
      @shorthands_forbidden = @config['allowed_shorthands'] == []
      yield # Continue linting children
    end

    # @param node [Sass::Tree::Node]
    def visit_prop(node)
      property_name = node.name.join
      return unless SHORTHANDABLE_PROPERTIES.include?(property_name)

      if @shorthands_forbidden
        add_lint(node, "The `#{property_name}` shorthand property is " \
                       'forbidden since the `allowed_shorthands` option ' \
                       'is set to an empty list.')

      end

      case node.value.first
      when Sass::Script::Tree::Literal
        check_script_literal(property_name, node.value.first)
      when Sass::Script::Tree::ListLiteral
        check_script_list(property_name, node.value.first)
      end
    end

  private

    SHORTHANDABLE_PROPERTIES = %w[
      border-color
      border-radius
      border-style
      border-width
      margin
      padding
    ].freeze

    # @param prop [String]
    # @param list [Sass::Script::Tree::ListLiteral]
    def check_script_list(prop, list)
      check_shorthand(prop, list, list.children.map(&:to_sass))
    end

    # @param prop [String]
    # @param literal [Sass::Script::Tree::Literal]
    def check_script_literal(prop, literal)
      value = literal.value

      # HACK: node_parent may not be initialized at this point, so we need to
      # set it ourselves
      value.node_parent = literal
      return unless value.is_a?(Sass::Script::Value::String)

      check_script_string(prop, value)
    end

    LIST_LITERAL_REGEX = /
      \A
      (\S+\s+\S+(\s+\S+){0,2})   # Two to four values separated by spaces
      (\s+!\w+)?                 # Ignore `!important` priority overrides
      \z
    /x.freeze

    # @param prop [String]
    # @param script_string [Sass::Script::Value::String]
    def check_script_string(prop, script_string)
      return unless script_string.type == :identifier
      return unless values = script_string.value.strip[LIST_LITERAL_REGEX, 1]

      check_shorthand(prop, script_string, values.split)
    end

    # @param prop [String]
    # @param node [Sass::Script::Value::String]
    # @param values [Array<String>]
    def check_shorthand(prop, node, values)
      values = shorthand_values(values)

      unless allowed?(values.count)
        add_lint(node, "Shorthands of length `#{values.count}` are not allowed. " \
                       "Value was `#{values.join(' ')}`")
      end

      return unless (2..4).member?(values.count)

      shortest_form = condensed_shorthand(*values)
      return if values == shortest_form

      add_lint(node, "Shorthand form for property `#{prop}` should be " \
                     "written more concisely as `#{shortest_form.join(' ')}` " \
                     "instead of `#{values.join(' ')}`")
    end

    # @param top [String]
    # @param right [String]
    # @param bottom [String]
    # @param left [String]
    # @return [Array]
    def condensed_shorthand(top, right, bottom = nil, left = nil)
      if condense_to_one_value?(top, right, bottom, left)
        [top]
      elsif condense_to_two_values?(top, right, bottom, left)
        [top, right]
      elsif condense_to_three_values?(top, right, bottom, left)
        [top, right, bottom]
      else
        [top, right, bottom, left].compact
      end
    end

    # @param top [String]
    # @param right [String]
    # @param bottom [String]
    # @param left [String]
    # @return [Boolean]
    def condense_to_one_value?(top, right, bottom, left) # rubocop:disable Metrics/CyclomaticComplexity
      return unless allowed?(1)
      return unless top == right

      top == bottom && (bottom == left || left.nil?) ||
        bottom.nil? && left.nil?
    end

    # @param top [String]
    # @param right [String]
    # @param bottom [String]
    # @param left [String]
    # @return [Boolean]
    def condense_to_two_values?(top, right, bottom, left)
      return unless allowed?(2)

      top == bottom && right == left ||
        top == bottom && left.nil? && top != right
    end

    # @param right [String]
    # @param left [String]
    # @return [Boolean]
    def condense_to_three_values?(_, right, _, left)
      return unless allowed?(3)

      right == left
    end

    # @param size [Number]
    # @return [Boolean]
    def allowed?(size)
      return false unless config['allowed_shorthands']
      config['allowed_shorthands'].map(&:to_i).include?(size)
    end

    def shorthand_values(values)
      values.take(4).take_while { |value| !value.to_s.start_with?('!') }
    end
  end
end
