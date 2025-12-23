# frozen_string_literal: true

require_relative 'constants'
require_relative 'utils'

module Rack

  # Sets the content-length header on responses that do not specify
  # a content-length or transfer-encoding header.  Note that this
  # does not fix responses that have an invalid content-length
  # header specified.
  class ContentLength
    include Rack::Utils

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = response = @app.call(env)

      if !STATUS_WITH_NO_ENTITY_BODY.key?(status.to_i) &&
         !headers[CONTENT_LENGTH] &&
         !headers[TRANSFER_ENCODING] &&
         body.respond_to?(:to_ary)

        response[2] = body = body.to_ary
        headers[CONTENT_LENGTH] = body.sum(&:bytesize).to_s
      end

      response
    end
  end
end
