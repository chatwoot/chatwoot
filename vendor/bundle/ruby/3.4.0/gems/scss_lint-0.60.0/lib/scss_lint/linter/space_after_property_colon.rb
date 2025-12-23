module SCSSLint
  # Checks for spaces following the colon that separates a property's name from
  # its value.
  class Linter::SpaceAfterPropertyColon < Linter
    include LinterRegistry

    def visit_rule(node)
      if config['style'] == 'aligned'
        check_properties_alignment(node)
      end

      yield # Continue linting children
    end

    def visit_prop(node)
      whitespace = whitespace_after_colon(node)

      case config['style']
      when 'no_space'
        check_for_no_spaces(node, whitespace)
      when 'one_space'
        check_for_one_space(node, whitespace)
      when 'at_least_one_space'
        check_for_at_least_one_space(node, whitespace)
      when 'one_space_or_newline'
        check_for_one_space_or_newline(node, whitespace)
      when 'at_least_one_space_or_newline'
        check_for_at_least_one_space_or_newline(node, whitespace)
      end

      yield # Continue linting children
    end

  private

    def check_for_no_spaces(node, whitespace)
      return if whitespace == []
      add_lint(node, 'Colon after property should not be followed by any spaces')
    end

    def check_for_one_space(node, whitespace)
      return if whitespace == [' ']
      add_lint(node, 'Colon after property should be followed by one space')
    end

    def check_for_at_least_one_space(node, whitespace)
      return if whitespace.uniq == [' ']
      add_lint(node, 'Colon after property should be followed by at least one space')
    end

    def check_for_one_space_or_newline(node, whitespace)
      return if [[' '], ["\n"]].include?(whitespace)
      return if whitespace[0] == "\n" && whitespace[1..-1].uniq == [' ']
      add_lint(node, 'Colon after property should be followed by one space or a newline')
    end

    def check_for_at_least_one_space_or_newline(node, whitespace)
      return if [[' '], ["\n"]].include?(whitespace.uniq)
      return if whitespace[0] == "\n" && whitespace[1..-1].uniq == [' ']
      add_lint(node, 'Colon after property should be followed by at least one space or newline')
    end

    def check_properties_alignment(rule_node)
      properties = rule_node.children.select { |node| node.is_a?(Sass::Tree::PropNode) }

      properties.each_slice(2) do |prop1, prop2|
        next unless prop2
        next unless value_offset(prop1) != value_offset(prop2)
        add_lint(prop1, 'Property values should be aligned')
        break
      end
    end

    # Offset of value for property
    def value_offset(prop)
      src_range = prop.name_source_range
      src_range.start_pos.offset +
        (src_range.end_pos.offset - src_range.start_pos.offset) +
        whitespace_after_colon(prop).take_while { |w| w == ' ' }.size
    end

    def whitespace_after_colon(node)
      whitespace = []
      offset = 0
      start_pos = node.name_source_range.start_pos

      # Find the colon after the property name
      offset = offset_to(start_pos, ':', offset) + 1

      # Count spaces after the colon
      while [' ', "\t", "\n"].include? character_at(start_pos, offset)
        whitespace << character_at(start_pos, offset)
        offset += 1
      end

      whitespace
    end
  end
end
