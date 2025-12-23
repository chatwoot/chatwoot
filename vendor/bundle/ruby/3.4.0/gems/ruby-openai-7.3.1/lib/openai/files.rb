module OpenAI
  class Files
    PURPOSES = %w[
      assistants
      batch
      fine-tune
      vision
    ].freeze

    def initialize(client:)
      @client = client
    end

    def list(parameters: {})
      @client.get(path: "/files", parameters: parameters)
    end

    def upload(parameters: {})
      file_input = parameters[:file]
      file = prepare_file_input(file_input: file_input)

      validate(file: file, purpose: parameters[:purpose], file_input: file_input)

      @client.multipart_post(
        path: "/files",
        parameters: parameters.merge(file: file)
      )
    ensure
      file.close if file.is_a?(File)
    end

    def retrieve(id:)
      @client.get(path: "/files/#{id}")
    end

    def content(id:)
      @client.get(path: "/files/#{id}/content")
    end

    def delete(id:)
      @client.delete(path: "/files/#{id}")
    end

    private

    def prepare_file_input(file_input:)
      if file_input.is_a?(String)
        File.open(file_input)
      elsif file_input.respond_to?(:read) && file_input.respond_to?(:rewind)
        file_input
      else
        raise ArgumentError, "Invalid file - must be a StringIO object or a path to a file."
      end
    end

    def validate(file:, purpose:, file_input:)
      raise ArgumentError, "`file` is required" if file.nil?
      unless PURPOSES.include?(purpose)
        raise ArgumentError, "`purpose` must be one of `#{PURPOSES.join(',')}`"
      end

      validate_jsonl(file: file) if file_input.is_a?(String) && file_input.end_with?(".jsonl")
    end

    def validate_jsonl(file:)
      file.each_line.with_index do |line, index|
        JSON.parse(line)
      rescue JSON::ParserError => e
        raise JSON::ParserError, "#{e.message} - found on line #{index + 1} of #{file}"
      end
    ensure
      file.rewind
    end
  end
end
