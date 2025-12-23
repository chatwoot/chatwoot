# frozen_string_literal: true

module Aws
  module Stubbing
    module Protocols
      class RestJson < Rest

        def body_for(_a, _b, rules, data)
          if eventstream?(rules)
            encode_eventstream_response(rules, data, Aws::Json::Builder)
          else
            Aws::Json::Builder.new(rules).serialize(data)
          end
        end

        def stub_error(error_code)
          http_resp = Seahorse::Client::Http::Response.new
          http_resp.status_code = 400
          http_resp.body = <<-JSON.strip
{
  "code": #{error_code.inspect},
  "message": "stubbed-response-error-message"
}
          JSON
          http_resp
        end

      end
    end
  end
end
