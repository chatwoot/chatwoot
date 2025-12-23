module SCSSLint
  # Checks for spaces after commas in argument lists.
  class Linter::SpaceAfterComma < Linter
    include LinterRegistry

    def visit_mixindef(node)
      check_definition(node, :mixin)
      yield
    end

    def visit_mixin(node)
      check_invocation(node, :mixin)
      yield
    end

    def visit_function(node)
      check_definition(node, :function)
      yield
    end

    def visit_script_funcall(node)
      check_invocation(node, :function)
      yield
    end

    def visit_script_listliteral(node)
      check_commas_after_args(node.elements, 'lists') if node.separator == :comma
      yield
    end

  private

    # Check parameters of a function/mixin definition
    def check_definition(node, type)
      # Use the default value's source range if one is defined, since that will
      # be the item with the comma after it
      args = node.args.map { |name, default_value| default_value || name }
      args << node.splat if node.splat

      check_commas_after_args(args, "#{type} parameters")
    end

    # Check arguments passed to a function/mixin invocation
    def check_invocation(node, type)
      args = sort_args_by_position(node.args,
                                   node.splat,
                                   node.keywords.values,
                                   node.kwarg_splat)

      check_commas_after_args(args, "#{type} arguments")
    end

    # Since keyword arguments are not guaranteed to be in order, use the source
    # range to order arguments so we check them in the order they were declared.
    def sort_args_by_position(*args)
      args.flatten.compact.sort_by do |arg|
        pos = arg.source_range.end_pos
        [pos.line, pos.offset]
      end
    end

    def valid_spaces_after_comma?(spaces)
      case config['style']
      when 'one_space'
        spaces == 1
      when 'no_space'
        spaces == 0
      when 'at_least_one_space'
        spaces >= 1
      end
    end

    # Check the comma after each argument in a list for a space following it,
    # reporting a lint using the given [arg_type].
    def check_commas_after_args(args, arg_type)
      # For each arg except the last, check the character following the comma
      args[0..-2].each do |arg|
        # Sometimes the line we're looking at doesn't even contain a comma!
        next unless engine.lines[arg.line - 1].include?(',')

        comma_position = find_comma_position(arg)

        # Check for space or newline after comma (we allow arguments to be split
        # up over multiple lines).
        spaces = 0
        while (char = character_at(comma_position, spaces + 1)) == ' '
          spaces += 1
        end
        next if char == "\n" || # Ignore trailing spaces
                valid_spaces_after_comma?(spaces)

        style_message = config['style'].tr('_', ' ')
        add_lint comma_position, "Commas in #{arg_type} should be followed by #{style_message}"
      end
    end

    # Find the comma following this argument.
    #
    # The Sass parser is unpredictable in where it marks the end of the
    # source range. Thus we need to start at the indicated range, and check
    # left and right of that range, gradually moving further outward until
    # we find the comma.
    def find_comma_position(arg) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      offset = 0
      pos = arg.source_range.end_pos

      if character_at(pos, offset) != ','
        loop do
          offset += 1
          break if (right_char = character_at(pos, offset)) == ','
          offset = -offset
          break if (left_char = character_at(pos, offset)) == ','
          offset = -offset

          next unless right_char.nil? && left_char.nil?
          offset = 0
          pos = Sass::Source::Position.new(pos.line + 1, 1)
          break if character_at(pos, offset) == ','
        end
      end

      Sass::Source::Position.new(pos.line, pos.offset + offset)
    end
  end
end
