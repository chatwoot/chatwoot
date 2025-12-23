module OpenAI
  class Runs
    def initialize(client:)
      @client = client.beta(assistants: OpenAI::Assistants::BETA_VERSION)
    end

    def list(thread_id:, parameters: {})
      @client.get(path: "/threads/#{thread_id}/runs", parameters: parameters)
    end

    def retrieve(thread_id:, id:)
      @client.get(path: "/threads/#{thread_id}/runs/#{id}")
    end

    def create(thread_id:, parameters: {}, query_parameters: {})
      @client.json_post(path: "/threads/#{thread_id}/runs", parameters: parameters,
                        query_parameters: query_parameters)
    end

    def modify(id:, thread_id:, parameters: {})
      @client.json_post(path: "/threads/#{thread_id}/runs/#{id}", parameters: parameters)
    end

    def cancel(id:, thread_id:)
      @client.post(path: "/threads/#{thread_id}/runs/#{id}/cancel")
    end

    def create_thread_and_run(parameters: {})
      @client.json_post(path: "/threads/runs", parameters: parameters)
    end

    def submit_tool_outputs(thread_id:, run_id:, parameters: {})
      @client.json_post(path: "/threads/#{thread_id}/runs/#{run_id}/submit_tool_outputs",
                        parameters: parameters)
    end
  end
end
