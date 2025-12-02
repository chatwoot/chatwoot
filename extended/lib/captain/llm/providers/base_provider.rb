module Captain
  module Llm
    module Providers
      class BaseProvider
        def initialize(api_key:, **options)
          raise NotImplementedError
        end

        def chat(messages:, model:, functions: [], json_mode: true)
          raise NotImplementedError
        end

        def embedding(text:, model:)
          raise NotImplementedError
        end
      end
    end
  end
end
