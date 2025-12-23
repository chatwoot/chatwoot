# frozen_string_literal: true

require "hashdiff"
require "json"

module WebMock
  class RequestBodyDiff

    def initialize(request_signature, request_stub)
      @request_signature = request_signature
      @request_stub      = request_stub
    end

    def body_diff
      return {} unless request_signature_diffable? && request_stub_diffable?

      Hashdiff.diff(request_signature_body_hash, request_stub_body_hash)
    end

    attr_reader :request_signature, :request_stub
    private :request_signature, :request_stub

    private

    def request_signature_diffable?
      request_signature.json_headers? && request_signature_parseable_json?
    end

    def request_stub_diffable?
      request_stub_body.is_a?(Hash) || request_stub_parseable_json?
    end

    def request_signature_body_hash
      JSON.parse(request_signature.body)
    end

    def request_stub_body_hash
      return request_stub_body if request_stub_body.is_a?(Hash)

      JSON.parse(request_stub_body)
    end

    def request_stub_body
      request_stub.request_pattern &&
        request_stub.request_pattern.body_pattern &&
        request_stub.request_pattern.body_pattern.pattern
    end

    def request_signature_parseable_json?
      parseable_json?(request_signature.body)
    end

    def request_stub_parseable_json?
      parseable_json?(request_stub_body)
    end

    def parseable_json?(body_pattern)
      return false unless body_pattern.is_a?(String)

      JSON.parse(body_pattern)
      true
    rescue JSON::ParserError
      false
    end
  end
end
