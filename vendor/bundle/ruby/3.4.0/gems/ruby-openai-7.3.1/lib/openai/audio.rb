module OpenAI
  class Audio
    def initialize(client:)
      @client = client
    end

    def transcribe(parameters: {})
      @client.multipart_post(path: "/audio/transcriptions", parameters: parameters)
    end

    def translate(parameters: {})
      @client.multipart_post(path: "/audio/translations", parameters: parameters)
    end

    def speech(parameters: {})
      @client.json_post(path: "/audio/speech", parameters: parameters)
    end
  end
end
