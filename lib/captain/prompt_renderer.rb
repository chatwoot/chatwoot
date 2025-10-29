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
      candidate_paths(template_name).each do |template_path|
        next unless File.exist?(template_path)

        return File.read(template_path)
      end

      raise "Template not found: #{template_name}"
    end

    def candidate_paths(template_name)
      [
        Rails.root.join('lib', 'captain', 'prompts', "#{template_name}.liquid")
      ]
    end

    def stringify_keys(hash)
      hash.deep_stringify_keys
    end
  end
end

Captain::PromptRenderer.singleton_class.prepend_mod_with('Captain::PromptRenderer')
