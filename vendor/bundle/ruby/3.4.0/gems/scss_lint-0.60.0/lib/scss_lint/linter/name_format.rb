module SCSSLint
  # Checks the format of declared names of functions, mixins, and variables.
  class Linter::NameFormat < Linter
    include LinterRegistry

    CSS_FUNCTION_WHITELIST = %w[
      rotateX rotateY rotateZ
      scaleX scaleY scaleZ
      skewX skewY
      translateX translateY translateZ
      linear-gradient repeating-linear-gradient
      radial-gradient repeating-radial-gradient
      cubic-bezier
      fit-content
    ].to_set.freeze

    SCSS_FUNCTION_WHITELIST = %w[
      adjust-hue adjust-color scale-color change-color ie-hex-str
      str-length str-insert str-index str-slice to-upper-case to-lower-case
      list-separator
      map-get map-merge map-remove map-keys map-values map-has-key
      selector-nest selector-append selector-extend selector-replace
      selector-unify is-superselector simple-selectors selector-parse
      feature-exists variable-exists global-variable-exists function-exists
      mixin-exists type-of
      unique-id
    ].to_set.freeze

    def visit_function(node)
      check_name(node, 'function')
      yield # Continue into content block of this function definition
    end

    def visit_mixin(node)
      check_name(node, 'mixin') unless whitelist?(node.name)
      yield # Continue into content block of this mixin's block
    end

    def visit_mixindef(node)
      check_name(node, 'mixin')
      yield # Continue into content block of this mixin definition
    end

    def visit_script_funcall(node)
      check_name(node, 'function') unless whitelist?(node.name)
      yield # Continue linting any arguments of this function call
    end

    def visit_script_variable(node)
      check_name(node, 'variable')
    end

    def visit_variable(node)
      check_name(node, 'variable')
      yield # Continue into expression tree for this variable definition
    end

  private

    def whitelist?(name)
      CSS_FUNCTION_WHITELIST.include?(name) ||
        SCSS_FUNCTION_WHITELIST.include?(name)
    end

    def check_name(node, node_type, node_text = node.name)
      node_text = trim_underscore_prefix(node_text)
      return unless violation = violated_convention(node_text, node_type)

      add_lint(node,
               "Name of #{node_type} `#{node_text}` #{violation[:explanation]}")
    end

    # Removes underscore prefix from name if leading underscores are allowed.
    def trim_underscore_prefix(name)
      if config['allow_leading_underscore']
        # Remove if there is a single leading underscore
        name = name.sub(/^_(?!_)/, '')
      end

      name
    end

    CONVENTIONS = {
      'camel_case' => {
        explanation: 'should be written in camelCase format',
        validator: ->(name) { name =~ /^[a-z][a-zA-Z0-9]*$/ },
      },
      'snake_case' => {
        explanation: 'should be written in snake_case',
        validator: ->(name) { name !~ /[^_a-z0-9]/ },
      },
      'hyphenated_lowercase' => {
        explanation: 'should be written in all lowercase letters with hyphens ' \
                     'instead of underscores',
        validator: ->(name) { name !~ /[_A-Z]/ },
      },
    }.freeze

    def violated_convention(name_string, type)
      convention_name = convention_name(type)

      existing_convention = CONVENTIONS[convention_name]

      convention = (existing_convention || {
        validator: ->(name) { name =~ /#{convention_name}/ }
      }).merge(
        explanation: convention_explanation(type), # Allow explanation to be customized
      )

      convention unless convention[:validator].call(name_string)
    end

    def convention_name(type)
      config["#{type}_convention"] ||
        config['convention'] ||
        'hyphenated_lowercase'
    end

    def convention_explanation(type)
      existing_convention = CONVENTIONS[convention_name(type)]

      config["#{type}_convention_explanation"] ||
        config['convention_explanation'] ||
        (existing_convention && existing_convention[:explanation]) ||
        "should match regex /#{convention_name(type)}/"
    end
  end
end
