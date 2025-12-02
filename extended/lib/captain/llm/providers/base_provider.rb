module Captain::Llm::Providers
  class BaseProvider
    def initialize(api_key:, **_options)
      # No-op, meant to be overridden or just accept args
    end

    def chat(messages:, model:, functions: [], json_mode: true)
      raise NotImplementedError
    end

    def embedding(text:, model:)
      raise NotImplementedError
    end
  end
end
