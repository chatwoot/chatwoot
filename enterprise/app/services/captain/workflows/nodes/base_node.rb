class Captain::Workflows::Nodes::BaseNode
  attr_reader :node_config, :context

  def initialize(node_config, context)
    @node_config = node_config
    @context = context
  end

  def execute
    raise NotImplementedError, "#{self.class} must implement #execute"
  end

  private

  def account
    context[:account]
  end

  def conversation
    context[:conversation]
  end

  def contact
    context[:contact]
  end

  def node_data
    node_config['data'] || {}
  end

  def interpolate(template)
    return template unless template.is_a?(String)

    template.gsub(/\{\{(\w+(?:\.\w+)*)\}\}/) do |match|
      keys = ::Regexp.last_match(1).split('.')
      value = context.dig(*keys.map(&:to_sym))
      value.nil? ? match : value.to_s
    end
  end
end
