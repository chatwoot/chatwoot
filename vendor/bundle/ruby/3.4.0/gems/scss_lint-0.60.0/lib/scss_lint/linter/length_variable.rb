module SCSSLint
  # Ensures length literals are used only in variable declarations.
  class Linter::LengthVariable < Linter
    include LinterRegistry

    LENGTH_UNITS = [
      'ch', 'em', 'ex', 'rem',                 # Font-relative lengths
      'cm', 'in', 'mm', 'pc', 'pt', 'px', 'q', # Absolute lengths
      'vh', 'vw', 'vmin', 'vmax'               # Viewport-percentage lengths
    ].freeze

    LENGTH_RE = %r{
      (?:^|[\s+\-/*()]) # math or space separated, or beginning of string
      ( # capture whole length
        0 # unitless zero
        |
        [-+]? # optional sign
        (?:
          \.\d+ # with leading decimal, e.g. .5
          |
          \d+(\.\d+)? # whole or maybe with trailing decimal
        )
        (?:#{LENGTH_UNITS.join('|')}) # unit!
      )
      (?:$|[\s+\-/*()]) # math or space separated, or end of string
    }x.freeze

    def visit_prop(node)
      return if allowed_prop?(node)
      lint_lengths(node)
    end

    def visit_mixindef(node)
      lint_lengths(node)
    end

    def visit_media(node)
      lint_lengths(node)
    end

    def visit_mixin(node)
      lint_lengths(node)
    end

  private

    def lint_lengths(node)
      lengths = extract_lengths(node)
      lengths = [lengths].flatten.compact.uniq
      lengths -= config['allowed_lengths'] if config['allowed_lengths']
      lengths.each do |length|
        record_lint(node, length) unless lengths.empty?
      end
    end

    def record_lint(node, length)
      add_lint node, "Length literals like `#{length}` should only be used in " \
                     'variable declarations; they should be referred to via ' \
                     'variables everywhere else.'
    end

    def allowed_prop?(node)
      config['allowed_properties'] && config['allowed_properties'].include?(node.name.first.to_s)
    end

    # Though long, This method is clear enough in a boring, dispatch kind of way.
    # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize
    def extract_lengths(node)
      case node
      when Sass::Tree::PropNode
        extract_lengths(node.value)
      when Sass::Script::Tree::Literal
        extract_lengths_from_string(node.value)
      when String
        extract_lengths_from_string(node)
      when Sass::Script::Tree::Funcall,
           Sass::Tree::MixinNode,
           Sass::Tree::MixinDefNode
        extract_lengths_from_list(*node.args)
      when Sass::Script::Tree::ListLiteral
        extract_lengths_from_list(*node.elements)
      when Sass::Tree::MediaNode
        extract_lengths_from_list(*node.query)
      when Array
        extract_lengths_from_list(*node)
      when Sass::Script::Tree::Interpolation
        extract_lengths_from_list(node.before, node.mid, node.after)
      when Sass::Script::Tree::Operation
        extract_lengths_from_list(node.operand1, node.operand2)
      when Sass::Script::Tree::UnaryOperation
        extract_lengths(node.operand)
      when Sass::Script::Tree::Variable
        nil
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize

    def extract_lengths_from_string(string)
      matchdata = string.to_s.match(LENGTH_RE)
      matchdata && matchdata.captures
    end

    def extract_lengths_from_list(*values)
      values.map { |v| extract_lengths(v) }
    end
  end
end
