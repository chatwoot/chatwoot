# frozen_string_literal: true

module OAuth2
  class Error < StandardError
    attr_reader :response, :body, :code, :description

    # standard error codes include:
    # 'invalid_request', 'invalid_client', 'invalid_token', 'invalid_grant', 'unsupported_grant_type', 'invalid_scope'
    # response might be a Response object, or the response.parsed hash
    def initialize(response)
      @response = response
      if response.respond_to?(:parsed)
        if response.parsed.is_a?(Hash)
          @code = response.parsed['error']
          @description = response.parsed['error_description']
        end
      elsif response.is_a?(Hash)
        @code = response['error']
        @description = response['error_description']
      end
      @body = if response.respond_to?(:body)
                response.body
              else
                @response
              end
      message_opts = parse_error_description(@code, @description)
      super(error_message(@body, message_opts))
    end

  private

    def error_message(response_body, opts = {})
      lines = []

      lines << opts[:error_description] if opts[:error_description]

      error_string = if response_body.respond_to?(:encode) && opts[:error_description].respond_to?(:encoding)
                       script_encoding = opts[:error_description].encoding
                       response_body.encode(script_encoding, invalid: :replace, undef: :replace)
                     else
                       response_body
                     end

      lines << error_string

      lines.join("\n")
    end

    def parse_error_description(code, description)
      return {} unless code || description

      error_description = ''
      error_description += "#{code}: " if code
      error_description += description if description

      {error_description: error_description}
    end
  end
end
