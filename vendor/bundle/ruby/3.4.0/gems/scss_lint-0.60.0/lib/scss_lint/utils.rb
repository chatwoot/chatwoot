module SCSSLint
  # Collection of helpers used across a variety of linters.
  module Utils
    COLOR_REGEX = /^#[a-f0-9]{3,6}$/i.freeze

    # Returns whether the given string is a color literal (keyword or hex code).
    #
    # @param string [String]
    # @return [true,false]
    def color?(string)
      color_keyword?(string) || color_hex?(string)
    end

    # Returns whether the given string is a color hexadecimal code.
    #
    # @param string [String]
    # @return [true,false]
    def color_hex?(string)
      string =~ COLOR_REGEX
    end

    # Returns whether the given string is a valid color keyword.
    #
    # @param string [String]
    # @return [true,false]
    def color_keyword?(string)
      color_keyword_to_code(string) && string != 'transparent'
    end

    # Returns the hexadecimal code for the given color keyword.
    #
    # @param string [String]
    # @return [String] 7-character hexadecimal code (includes `#` prefix)
    def color_keyword_to_code(string)
      Sass::Script::Value::Color::COLOR_NAMES[string]
    end

    # Returns whether a node is an IfNode corresponding to an @else/@else if
    # statement.
    #
    # @param node [Sass::Tree::Node]
    # @return [true,false]
    def else_node?(node)
      source_from_range(node.source_range).strip.start_with?('@else')
    end

    # Given a selector array which is a list of strings with Sass::Script::Nodes
    # interspersed within them, return an array of strings representing those
    # selectors with the Sass::Script::Nodes removed (i.e., ignoring
    # interpolation). For example:
    #
    # .selector-one, .selector-#{$var}-two
    #
    # becomes:
    #
    # .selector-one, .selector--two
    #
    # This is useful for lints that wish to ignore interpolation, since
    # interpolation can't be resolved at this step.
    def extract_string_selectors(selector_array)
      selector_array.reject { |item| item.is_a? Sass::Script::Node }
                    .join
                    .split
    end

    # Takes a string like `hello "world" 'how are' you` and turns it into:
    # `hello   you`.
    # This is useful for scanning for keywords in shorthand properties or lists
    # which can contain quoted strings but for which you don't want to inspect
    # quoted strings (e.g. you care about the actual color keyword `red`, not
    # the string "red").
    def remove_quoted_strings(string)
      string.gsub(/"[^"]*"|'[^']*'/, '')
    end

    def previous_node(node)
      return unless node && parent = node.node_parent
      index = parent.children.index(node)

      if index == 0
        parent
      else
        parent.children[index - 1]
      end
    end

    def node_siblings(node)
      return unless node && node.node_parent
      node.node_parent
          .children
          .select { |child| child.is_a?(Sass::Tree::Node) }
    end

    # Return nth-ancestor of a node, where 1 is the parent, 2 is grandparent,
    # etc.
    #
    # @param node [Sass::Tree::Node, Sass::Script::Tree::Node]
    # @param level [Integer]
    # @return [Sass::Tree::Node, Sass::Script::Tree::Node, nil]
    def node_ancestor(node, levels)
      while levels > 0
        node = node.node_parent
        return unless node
        levels -= 1
      end

      node
    end

    def pluralize(value, word)
      value == 1 ? "#{value} #{word}" : "#{value} #{word}s"
    end

    # Sass doesn't define an equality operator for Sass::Source::Position
    # objects, so we define a helper for our own use.
    def same_position?(pos1, pos2)
      return unless pos1 && pos2
      pos1.line == pos2.line && pos1.offset == pos2.offset
    end
  end
end
