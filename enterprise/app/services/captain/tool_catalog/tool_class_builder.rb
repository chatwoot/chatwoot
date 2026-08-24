class Captain::ToolCatalog::ToolClassBuilder
  def initialize(custom_tool:, base_class:, namespace:)
    @custom_tool = custom_tool
    @base_class = base_class
    @namespace = namespace
  end

  def build
    tool_slug = custom_tool.slug
    klass = Class.new(base_class)
    klass.description(custom_tool.description)
    klass.define_method(:name) { tool_slug }
    custom_tool.source_catalog? ? configure_catalog_schema(klass) : configure_legacy_parameters(klass)
    register(klass)
  end

  private

  attr_reader :custom_tool, :base_class, :namespace

  def configure_catalog_schema(klass)
    klass.params(custom_tool.input_schema.deep_dup)
    klass.define_singleton_method(:params) do |schema = nil, &block|
      return params_schema_definition if schema.nil? && !block

      super(schema, &block)
    end
  end

  def configure_legacy_parameters(klass)
    custom_tool.param_schema.each do |definition|
      klass.param definition['name'].to_sym,
                  type: definition['type'],
                  desc: definition['description'],
                  required: definition.fetch('required', true)
    end
  end

  def register(klass)
    class_name = custom_tool.slug.underscore.camelize
    namespace.send(:remove_const, class_name) if namespace.const_defined?(class_name, false)
    namespace.const_set(class_name, klass)
  end
end
