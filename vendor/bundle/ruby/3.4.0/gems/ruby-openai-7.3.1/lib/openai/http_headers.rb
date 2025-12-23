module OpenAI
  module HTTPHeaders
    def add_headers(headers)
      @extra_headers = extra_headers.merge(headers.transform_keys(&:to_s))
    end

    private

    def headers
      if azure?
        azure_headers
      else
        openai_headers
      end.merge(extra_headers)
    end

    def openai_headers
      {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@access_token}",
        "OpenAI-Organization" => @organization_id
      }.compact
    end

    def azure_headers
      {
        "Content-Type" => "application/json",
        "api-key" => @access_token
      }
    end

    def extra_headers
      @extra_headers ||= {}
    end
  end
end
