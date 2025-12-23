# frozen_string_literal: true

module Rack
  # Rack::NotFound is a default endpoint. Optionally initialize with the
  # path to a custom 404 page, to override the standard response body.
  #
  # Examples:
  #
  # Serve default 404 response:
  #   run Rack::NotFound.new
  #
  # Serve a custom 404 page:
  #   run Rack::NotFound.new('path/to/your/404.html')

  class NotFound
    F = ::File

    def initialize(path = nil, content_type = 'text/html')
      if path.nil?
        @content = "Not found\n"
      else
        @content = F.read(path)
      end
      @length = @content.bytesize.to_s

      @content_type = content_type
    end

    def call(env)
      [404, {'content-type' => @content_type, 'content-length' => @length}, [@content]]
    end
  end
end
