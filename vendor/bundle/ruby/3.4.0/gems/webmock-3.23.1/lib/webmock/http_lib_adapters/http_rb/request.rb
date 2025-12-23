# frozen_string_literal: true

module HTTP
  class Request
    def webmock_signature
      request_body = nil

      if defined?(HTTP::Request::Body)
        request_body = String.new
        first_chunk_encoding = nil
        body.each do |part|
          request_body << part
          first_chunk_encoding ||= part.encoding
        end

        request_body.force_encoding(first_chunk_encoding) if first_chunk_encoding
        request_body
      else
        request_body = body
      end

      ::WebMock::RequestSignature.new(verb, uri.to_s, {
        headers: headers.to_h,
        body: request_body
      })
    end
  end
end
