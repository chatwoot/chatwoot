module OpenAI
  class Finetunes
    def initialize(client:)
      @client = client
    end

    def list
      @client.get(path: "/fine_tuning/jobs")
    end

    def create(parameters: {})
      @client.json_post(path: "/fine_tuning/jobs", parameters: parameters)
    end

    def retrieve(id:)
      @client.get(path: "/fine_tuning/jobs/#{id}")
    end

    def cancel(id:)
      @client.json_post(path: "/fine_tuning/jobs/#{id}/cancel", parameters: {})
    end

    def list_events(id:)
      @client.get(path: "/fine_tuning/jobs/#{id}/events")
    end
  end
end
