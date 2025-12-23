module OpenAI
  class Threads
    def initialize(client:)
      @client = client.beta(assistants: OpenAI::Assistants::BETA_VERSION)
    end

    def retrieve(id:)
      @client.get(path: "/threads/#{id}")
    end

    def create(parameters: {})
      @client.json_post(path: "/threads", parameters: parameters)
    end

    def modify(id:, parameters: {})
      @client.json_post(path: "/threads/#{id}", parameters: parameters)
    end

    def delete(id:)
      @client.delete(path: "/threads/#{id}")
    end
  end
end
