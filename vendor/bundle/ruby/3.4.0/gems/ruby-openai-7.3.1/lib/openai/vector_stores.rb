module OpenAI
  class VectorStores
    def initialize(client:)
      @client = client.beta(assistants: OpenAI::Assistants::BETA_VERSION)
    end

    def list(parameters: {})
      @client.get(path: "/vector_stores", parameters: parameters)
    end

    def retrieve(id:)
      @client.get(path: "/vector_stores/#{id}")
    end

    def create(parameters: {})
      @client.json_post(path: "/vector_stores", parameters: parameters)
    end

    def modify(id:, parameters: {})
      @client.json_post(path: "/vector_stores/#{id}", parameters: parameters)
    end

    def delete(id:)
      @client.delete(path: "/vector_stores/#{id}")
    end
  end
end
