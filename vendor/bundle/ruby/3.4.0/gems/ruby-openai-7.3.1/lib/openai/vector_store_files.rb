module OpenAI
  class VectorStoreFiles
    def initialize(client:)
      @client = client.beta(assistants: OpenAI::Assistants::BETA_VERSION)
    end

    def list(vector_store_id:, parameters: {})
      @client.get(path: "/vector_stores/#{vector_store_id}/files", parameters: parameters)
    end

    def retrieve(vector_store_id:, id:)
      @client.get(path: "/vector_stores/#{vector_store_id}/files/#{id}")
    end

    def create(vector_store_id:, parameters: {})
      @client.json_post(path: "/vector_stores/#{vector_store_id}/files", parameters: parameters)
    end

    def delete(vector_store_id:, id:)
      @client.delete(path: "/vector_stores/#{vector_store_id}/files/#{id}")
    end
  end
end
