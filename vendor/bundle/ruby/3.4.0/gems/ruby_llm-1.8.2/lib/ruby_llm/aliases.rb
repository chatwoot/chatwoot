# frozen_string_literal: true

module RubyLLM
  # Manages model aliases for provider-specific versions
  class Aliases
    class << self
      def resolve(model_id, provider = nil)
        return model_id unless aliases[model_id]

        if provider
          aliases[model_id][provider.to_s] || model_id
        else
          aliases[model_id].values.first || model_id
        end
      end

      def aliases
        @aliases ||= load_aliases
      end

      def aliases_file
        File.expand_path('aliases.json', __dir__)
      end

      def load_aliases
        if File.exist?(aliases_file)
          JSON.parse(File.read(aliases_file))
        else
          {}
        end
      end

      def reload!
        @aliases = load_aliases
      end
    end
  end
end
