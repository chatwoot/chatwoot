require 'liquid'

class Captain::PromptRenderer
  class << self
    def render(template_name, context = {})
      template = load_template(template_name)
      liquid_template = Liquid::Template.parse(template)
      liquid_template.render(stringify_keys(context))
    end

    private

    def load_template(template_name)
      template_path = Rails.root.join('enterprise', 'lib', 'captain', 'prompts', "#{template_name}.liquid")

      raise "Template not found: #{template_name}" unless File.exist?(template_path)

      File.read(template_path)
    end

    def stringify_keys(hash)
      hash.deep_stringify_keys
    end
  end
end
