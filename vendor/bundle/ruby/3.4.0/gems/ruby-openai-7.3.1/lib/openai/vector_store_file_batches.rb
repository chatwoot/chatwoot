module OpenAI
  class VectorStoreFileBatches
    def initialize(client:)
      @client = client.beta(assistants: OpenAI::Assistants::BETA_VERSION)
    end

    def list(vector_store_id:, id:, parameters: {})
      @client.get(
        path: "/vector_stores/#{vector_store_id}/file_batches/#{id}/files",
        parameters: parameters
      )
    end

    def retrieve(vector_store_id:, id:)
      @client.get(path: "/vector_stores/#{vector_store_id}/file_batches/#{id}")
    end

    def create(vector_store_id:, parameters: {})
      @client.json_post(
        path: "/vector_stores/#{vector_store_id}/file_batches",
        parameters: parameters
      )
    end

    def cancel(vector_store_id:, id:)
      @client.post(path: "/vector_stores/#{vector_store_id}/file_batches/#{id}/cancel")
    end
  end
end
