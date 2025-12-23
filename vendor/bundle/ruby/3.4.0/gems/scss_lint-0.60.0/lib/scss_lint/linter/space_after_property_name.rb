module SCSSLint
  # Checks for spaces following the name of a property and before the colon
  # separating the property's name from its value.
  class Linter::SpaceAfterPropertyName < Linter
    include LinterRegistry

    def visit_prop(node)
      offset = property_name_colon_offset(node)
      return unless character_at(node.name_source_range.start_pos, offset - 1) == ' '
      add_lint node, 'Property name should be immediately followed by a colon'
    end

  private

    # Deals with a weird Sass bug where the name_source_range of a PropNode does
    # not start at the beginning of the property name.
    def property_name_colon_offset(node)
      offset_to(node.name_source_range.start_pos, ':')
    end
  end
end
