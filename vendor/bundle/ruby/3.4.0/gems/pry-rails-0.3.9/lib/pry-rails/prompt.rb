module PryRails
  class Prompt
    class << self
      def formatted_env
        if Rails.env.production?
          bold_env = Pry::Helpers::Text.bold(Rails.env)
          Pry::Helpers::Text.red(bold_env)
        elsif Rails.env.development?
          Pry::Helpers::Text.green(Rails.env)
        else
          Rails.env
        end
      end

      def project_name
        if Rails::VERSION::MAJOR >= 6
          Rails.application.class.module_parent_name.underscore
        else
          Rails.application.class.parent_name.underscore
        end
      end
    end
  end

  desc = "Includes the current Rails environment and project folder name.\n" \
          "[1] [project_name][Rails.env] pry(main)>"
  if Pry::Prompt.respond_to?(:add)
    Pry::Prompt.add 'rails', desc, %w(> *) do |target_self, nest_level, pry, sep|
      "[#{pry.input_ring.size}] " \
      "[#{Prompt.project_name}][#{Prompt.formatted_env}] " \
      "#{pry.config.prompt_name}(#{Pry.view_clip(target_self)})" \
      "#{":#{nest_level}" unless nest_level.zero?}#{sep} "
    end
  else
    draw_prompt = lambda do |target_self, nest_level, pry, sep|
      "[#{pry.input_array.size}] " \
      "[#{Prompt.project_name}][#{Prompt.formatted_env}] " \
      "#{pry.config.prompt_name}(#{Pry.view_clip(target_self)})" \
      "#{":#{nest_level}" unless nest_level.zero?}#{sep} "
    end
    prompts = [
      proc do |target_self, nest_level, pry|
        draw_prompt.call(target_self, nest_level, pry, '>')
      end,
      proc do |target_self, nest_level, pry|
        draw_prompt.call(target_self, nest_level, pry, '*')
      end
    ]
    Pry::Prompt::MAP["rails"] = {value: prompts, description: desc}
  end
end
