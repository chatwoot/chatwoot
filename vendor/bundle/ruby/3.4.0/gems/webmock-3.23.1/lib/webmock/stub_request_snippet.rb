# frozen_string_literal: true

module WebMock
  class StubRequestSnippet
    def initialize(request_stub)
      @request_stub = request_stub
    end

    def body_pattern
      request_pattern.body_pattern
    end

    def to_s(with_response = true)
      request_pattern = @request_stub.request_pattern
      string = "stub_request(:#{request_pattern.method_pattern.to_s},".dup
      string << " \"#{request_pattern.uri_pattern.to_s}\")"

      with = "".dup

      if (request_pattern.body_pattern)
        with << "\n    body: #{request_pattern.body_pattern.to_s}"
      end

      if (request_pattern.headers_pattern)
        with << "," unless with.empty?

        with << "\n    headers: #{request_pattern.headers_pattern.pp_to_s}"
      end
      string << ".\n  with(#{with})" unless with.empty?
      if with_response
        if request_pattern.headers_pattern && request_pattern.headers_pattern.matches?({ 'Accept' => "application/json" })
          string << ".\n  to_return(status: 200, body: \"{}\", headers: {})"
        else
          string << ".\n  to_return(status: 200, body: \"\", headers: {})"
        end
      end
      string
    end
  end
end
