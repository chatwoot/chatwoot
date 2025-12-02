require 'liquid'

class Captain::PromptRenderer
  def self.render(template_name, context = {})
    new(template_name, context).render
  end

  attr_reader :template_name, :context

  def initialize(template_name, context)
    @template_name = template_name
    @context = context
  end

  def render
    template = File.read(template_path)
    liquid_template = Liquid::Template.parse(template)
    liquid_template.render(context.deep_stringify_keys)
  rescue Errno::ENOENT
    raise "Template not found: #{template_name}"
  end

  private

  def template_path
    Rails.root.join('extended', 'lib', 'captain', 'prompts', "#{template_name}.liquid")
  end
end
