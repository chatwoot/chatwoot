module SCSSLint
  # Checks spacing of ! declarations, like !important and !default
  class Linter::BangFormat < Linter
    include LinterRegistry

    STOPPING_CHARACTERS = ['!', "'", '"', nil].freeze

    def visit_extend(node)
      check_bang(node)
    end

    def visit_prop(node)
      check_bang(node)
    end

    def visit_variable(node)
      check_bang(node)
    end

  private

    def check_bang(node)
      range = if node.respond_to?(:value_source_range)
                node.value_source_range
              else
                node.source_range
              end
      return unless source_from_range(range).include?('!')
      return unless check_spacing(range)

      before_qualifier = config['space_before_bang'] ? '' : 'not '
      after_qualifier = config['space_after_bang'] ? '' : 'not '

      add_lint(node, "! should #{before_qualifier}be preceded by a space, " \
                     "and should #{after_qualifier}be followed by a space")
    end

    # Start from the back and move towards the front so that any !important or
    # !default !'s will be found *before* quotation marks. Then we can
    # stop at quotation marks to protect against linting !'s within strings
    # (e.g. `content`)
    def find_bang_offset(range)
      offset = 0
      offset -= 1 until STOPPING_CHARACTERS.include?(character_at(range.end_pos, offset))
      offset
    end

    def is_before_wrong?(range, offset)
      before_expected = config['space_before_bang'] ? / / : /[^ ]/
      before_actual = character_at(range.end_pos, offset - 1)
      (before_actual =~ before_expected).nil?
    end

    def is_after_wrong?(range, offset)
      after_expected = config['space_after_bang'] ? / / : /[^ ]/
      after_actual = character_at(range.end_pos, offset + 1)
      (after_actual =~ after_expected).nil?
    end

    def check_spacing(range)
      offset = find_bang_offset(range)

      return if character_at(range.end_pos, offset) != '!'

      is_before_wrong?(range, offset) || is_after_wrong?(range, offset)
    end
  end
end
