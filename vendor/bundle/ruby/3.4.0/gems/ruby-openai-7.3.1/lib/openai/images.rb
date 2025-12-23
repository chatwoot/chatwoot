module OpenAI
  class Images
    def initialize(client: nil)
      @client = client
    end

    def generate(parameters: {})
      @client.json_post(path: "/images/generations", parameters: parameters)
    end

    def edit(parameters: {})
      @client.multipart_post(path: "/images/edits", parameters: open_files(parameters))
    end

    def variations(parameters: {})
      @client.multipart_post(path: "/images/variations", parameters: open_files(parameters))
    end

    private

    def open_files(parameters)
      parameters = parameters.merge(image: File.open(parameters[:image]))
      parameters = parameters.merge(mask: File.open(parameters[:mask])) if parameters[:mask]
      parameters
    end
  end
end
