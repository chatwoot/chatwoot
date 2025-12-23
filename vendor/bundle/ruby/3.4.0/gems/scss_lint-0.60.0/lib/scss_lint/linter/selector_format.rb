module SCSSLint
  # Checks that selector names use a specified convention
  class Linter::SelectorFormat < Linter
    include LinterRegistry

    def visit_root(_node)
      @ignored_names = Array(config['ignored_names']).to_set
      @ignored_types = Array(config['ignored_types']).to_set
      yield
    end

    def visit_attribute(attribute)
      check(attribute, 'attribute') unless @ignored_types.include?('attribute')
    end

    def visit_class(klass)
      check(klass, 'class') unless @ignored_types.include?('class')
    end

    def visit_element(element)
      check(element, 'element') unless @ignored_types.include?('element')
    end

    def visit_id(id)
      check(id, 'id') unless @ignored_types.include?('id')
    end

    def visit_placeholder(placeholder)
      check(placeholder, 'placeholder') unless @ignored_types.include?('placeholder')
    end

  private

    def check(node, type)
      name = node.name

      return if @ignored_names.include?(name)
      return unless violation = violated_convention(name, type)

      add_lint(node, "Selector `#{name}` #{violation[:explanation]}")
    end

    CONVENTIONS = {
      'hyphenated_lowercase' => {
        explanation: 'should be written in lowercase with hyphens',
        validator: ->(name) { name !~ /[^\-a-z0-9]/ },
      },
      'snake_case' => {
        explanation: 'should be written in lowercase with underscores',
        validator: ->(name) { name !~ /[^_a-z0-9]/ },
      },
      'camel_case' => {
        explanation: 'should be written in camelCase format',
        validator: ->(name) { name =~ /^[a-z][a-zA-Z0-9]*$/ },
      },
      'classic_BEM' => {
        explanation: 'should be written in classic BEM (Block Element Modifier) format',
        validator: lambda do |name|
          name =~ /
            ^[a-z]([-]?[a-z0-9]+)*
            (__[a-z0-9]([-]?[a-z0-9]+)*)?
            ((_[a-z0-9]([-]?[a-z0-9]+)*){1,2})?$
          /x
        end
      },
      'hyphenated_BEM' => {
        explanation: 'should be written in hyphenated BEM (Block Element Modifier) format',
        validator: ->(name) { name !~ /[A-Z]|-{3}|_{3}|[^_]_[^_]/ },
      },
      'strict_BEM' => {
        explanation: 'should be written in BEM (Block Element Modifier) format',
        validator: lambda do |name|
          name =~ /
            ^[a-z]([-]?[a-z0-9]+)*
            (__[a-z0-9]([-]?[a-z0-9]+)*)?
            ((_[a-z0-9]([-]?[a-z0-9]+)*){2})?$
          /x
        end,
      },
    }.freeze

    # Checks the given name and returns the violated convention if it failed.
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
