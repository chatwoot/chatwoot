module OpenAI
  class RunSteps
    def initialize(client:)
      @client = client.beta(assistants: OpenAI::Assistants::BETA_VERSION)
    end

    def list(thread_id:, run_id:, parameters: {})
      @client.get(path: "/threads/#{thread_id}/runs/#{run_id}/steps", parameters: parameters)
    end

    def retrieve(thread_id:, run_id:, id:, parameters: {})
      @client.get(path: "/threads/#{thread_id}/runs/#{run_id}/steps/#{id}", parameters: parameters)
    end
  end
end
