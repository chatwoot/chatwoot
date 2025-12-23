# frozen_string_literal: true

module Twilio
  class Response
    attr_accessor :status_code, :body, :headers

    def initialize(status_code, body, headers: nil)
      @status_code = status_code
      body = '{}' if !body || body.empty?
      @body = JSON.parse(body)
      @headers = !headers ? {} : headers.to_hash
    end

    def to_s
      "[#{status_code}] #{body}"
    end
  end
end
