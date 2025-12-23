# frozen_string_literal: true

require_relative 'constants'
require_relative 'utils'

module Rack

  # Sets the content-type header on responses which don't have one.
  #
  # Builder Usage:
  #   use Rack::ContentType, "text/plain"
  #
  # When no content type argument is provided, "text/html" is the
  # default.
  class ContentType
    include Rack::Utils

    def initialize(app, content_type = "text/html")
      @app = app
      @content_type = content_type
    end

    def call(env)
      status, headers, _ = response = @app.call(env)

      unless STATUS_WITH_NO_ENTITY_BODY.key?(status.to_i)
        headers[CONTENT_TYPE] ||= @content_type
      end

      response
    end
  end
end
