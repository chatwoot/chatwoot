module OpenAI
  class Batches
    def initialize(client:)
      @client = client.beta(assistants: OpenAI::Assistants::BETA_VERSION)
    end

    def list(parameters: {})
      @client.get(path: "/batches", parameters: parameters)
    end

    def retrieve(id:)
      @client.get(path: "/batches/#{id}")
    end

    def create(parameters: {})
      @client.json_post(path: "/batches", parameters: parameters)
    end

    def cancel(id:)
      @client.post(path: "/batches/#{id}/cancel")
    end
  end
end
