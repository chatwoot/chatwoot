# frozen_string_literal: true

module RubyLLM
  # Registry of available AI models and their capabilities.
  class Models
    include Enumerable

    class << self
      def instance
        @instance ||= new
      end

      def provider_for(model)
        Provider.for(model)
      end

      def models_file
        File.expand_path('models.json', __dir__)
      end

      def schema_file
        File.expand_path('models_schema.json', __dir__)
      end

      def refresh!(remote_only: false)
        provider_models = fetch_from_providers(remote_only: remote_only)
        parsera_models = fetch_from_parsera
        merged_models = merge_models(provider_models, parsera_models)
        @instance = new(merged_models)
      end

      def fetch_from_providers(remote_only: true)
        config = RubyLLM.config
        configured_classes = if remote_only
                               Provider.configured_remote_providers(config)
                             else
                               Provider.configured_providers(config)
                             end
        configured = configured_classes.map { |klass| klass.new(config) }

        RubyLLM.logger.info "Fetching models from providers: #{configured.map(&:name).join(', ')}"

        configured.flat_map(&:list_models)
      end

      def resolve(model_id, provider: nil, assume_exists: false, config: nil) # rubocop:disable Metrics/PerceivedComplexity
        config ||= RubyLLM.config
        provider_class = provider ? Provider.providers[provider.to_sym] : nil

        if provider_class
          temp_instance = provider_class.new(config)
          assume_exists = true if temp_instance.local?
        end

        if assume_exists
          raise ArgumentError, 'Provider must be specified if assume_exists is true' unless provider

          provider_class ||= raise(Error, "Unknown provider: #{provider.to_sym}")
          provider_instance = provider_class.new(config)

          model = if provider_instance.local?
                    begin
                      Models.find(model_id, provider)
                    rescue ModelNotFoundError
                      nil
                    end
                  end

          model ||= Model::Info.default(model_id, provider_instance.slug)
        else
          model = Models.find model_id, provider
          provider_class = Provider.providers[model.provider.to_sym] || raise(Error,
                                                                              "Unknown provider: #{model.provider}")
          provider_instance = provider_class.new(config)
        end
        [model, provider_instance]
      end

      def method_missing(method, ...)
        if instance.respond_to?(method)
          instance.send(method, ...)
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        instance.respond_to?(method, include_private) || super
      end

      def fetch_from_parsera
        RubyLLM.logger.info 'Fetching models from Parsera API...'

        connection = Connection.basic do |f|
          f.request :json
          f.response :json, parser_options: { symbolize_names: true }
        end
        response = connection.get 'https://api.parsera.org/v1/llm-specs'
        models = response.body.map { |data| Model::Info.new(data) }
        models.reject { |model| model.provider.nil? || model.id.nil? }
      end

      def merge_models(provider_models, parsera_models)
        parsera_by_key = index_by_key(parsera_models)
        provider_by_key = index_by_key(provider_models)

        all_keys = parsera_by_key.keys | provider_by_key.keys

        models = all_keys.map do |key|
          parsera_model = find_parsera_model(key, parsera_by_key)
          provider_model = provider_by_key[key]

          if parsera_model && provider_model
            add_provider_metadata(parsera_model, provider_model)
          elsif parsera_model
            parsera_model
          else
            provider_model
          end
        end

        models.sort_by { |m| [m.provider, m.id] }
      end

      def find_parsera_model(key, parsera_by_key)
        # Direct match
        return parsera_by_key[key] if parsera_by_key[key]

        # VertexAI uses same models as Gemini
        provider, model_id = key.split(':', 2)
        return unless provider == 'vertexai'

        gemini_model = parsera_by_key["gemini:#{model_id}"]
        return unless gemini_model

        # Return Gemini's Parsera data but with VertexAI as provider
        Model::Info.new(gemini_model.to_h.merge(provider: 'vertexai'))
      end

      def index_by_key(models)
        models.each_with_object({}) do |model, hash|
          hash["#{model.provider}:#{model.id}"] = model
        end
      end

      def add_provider_metadata(parsera_model, provider_model)
        data = parsera_model.to_h
        data[:metadata] = provider_model.metadata.merge(data[:metadata] || {})
        Model::Info.new(data)
      end
    end

    def initialize(models = nil)
      @models = models || load_models
    end

    def load_models
      read_from_json
    end

    def load_from_json!
      @models = read_from_json
    end

    def read_from_json
      data = File.exist?(self.class.models_file) ? File.read(self.class.models_file) : '[]'
      JSON.parse(data, symbolize_names: true).map { |model| Model::Info.new(model) }
    rescue JSON::ParserError
      []
    end

    def save_to_json
      File.write(self.class.models_file, JSON.pretty_generate(all.map(&:to_h)))
    end

    def all
      @models
    end

    def each(&)
      all.each(&)
    end

    def find(model_id, provider = nil)
      if provider
        find_with_provider(model_id, provider)
      else
        find_without_provider(model_id)
      end
    end

    def chat_models
      self.class.new(all.select { |m| m.type == 'chat' })
    end

    def embedding_models
      self.class.new(all.select { |m| m.type == 'embedding' || m.modalities.output.include?('embeddings') })
    end

    def audio_models
      self.class.new(all.select { |m| m.type == 'audio' || m.modalities.output.include?('audio') })
    end

    def image_models
      self.class.new(all.select { |m| m.type == 'image' || m.modalities.output.include?('image') })
    end

    def by_family(family)
      self.class.new(all.select { |m| m.family == family.to_s })
    end

    def by_provider(provider)
      self.class.new(all.select { |m| m.provider == provider.to_s })
    end

    def refresh!(remote_only: false)
      self.class.refresh!(remote_only: remote_only)
    end

    def resolve(model_id, provider: nil, assume_exists: false, config: nil)
      self.class.resolve(model_id, provider: provider, assume_exists: assume_exists, config: config)
    end

    private

    def find_with_provider(model_id, provider)
      resolved_id = Aliases.resolve(model_id, provider)
      all.find { |m| m.id == model_id && m.provider == provider.to_s } ||
        all.find { |m| m.id == resolved_id && m.provider == provider.to_s } ||
        raise(ModelNotFoundError, "Unknown model: #{model_id} for provider: #{provider}")
    end

    def find_without_provider(model_id)
      all.find { |m| m.id == model_id } ||
        all.find { |m| m.id == Aliases.resolve(model_id) } ||
        raise(ModelNotFoundError, "Unknown model: #{model_id}")
    end
  end
end
