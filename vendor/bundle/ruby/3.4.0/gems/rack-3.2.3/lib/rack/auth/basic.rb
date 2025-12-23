# frozen_string_literal: true

require_relative 'abstract/handler'
require_relative 'abstract/request'

module Rack
  module Auth
    # Rack::Auth::Basic implements HTTP Basic Authentication, as per RFC 2617.
    #
    # Initialize with the Rack application that you want protecting,
    # and a block that checks if a username and password pair are valid.

    class Basic < AbstractHandler

      def call(env)
        auth = Basic::Request.new(env)

        return unauthorized unless auth.provided?

        return bad_request unless auth.basic?

        if valid?(auth)
          env['REMOTE_USER'] = auth.username

          return @app.call(env)
        end

        unauthorized
      end


      private

      def challenge
        'Basic realm="%s"' % realm
      end

      def valid?(auth)
        @authenticator.call(*auth.credentials)
      end

      class Request < Auth::AbstractRequest
        def basic?
          "basic" == scheme && credentials.length == 2
        end

        def credentials
          @credentials ||= params.unpack1('m').split(':', 2)
        end

        def username
          credentials.first
        end
      end

    end
  end
end
