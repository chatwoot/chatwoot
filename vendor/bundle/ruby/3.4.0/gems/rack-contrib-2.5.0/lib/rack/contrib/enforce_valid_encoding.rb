# frozen_string_literal: true

module Rack
  # Ensure that the path and query string presented to the application
  # contains only valid characters.  If the validation fails, then a
  # 400 Bad Request response is returned immediately.
  #
  # Requires: Ruby 1.9
  #
  class EnforceValidEncoding
    def initialize app
      @app = app
    end

    def call env
      full_path = (env.fetch('PATH_INFO', '') + env.fetch('QUERY_STRING', ''))
      if full_path.force_encoding("US-ASCII").valid_encoding? &&
         Rack::Utils.unescape(full_path).valid_encoding?
        @app.call env
      else
        [400, {'content-type'=>'text/plain'}, ['Bad Request']]
      end
    end
  end
end
