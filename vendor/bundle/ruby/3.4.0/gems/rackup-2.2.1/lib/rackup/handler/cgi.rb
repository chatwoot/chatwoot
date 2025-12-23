# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.

module Rackup
  module Handler
    class CGI
      include Rack

      def self.run(app, **options)
        $stdin.binmode
        serve app
      end

      def self.serve(app)
        env = ENV.to_hash
        env.delete "HTTP_CONTENT_LENGTH"

        env[SCRIPT_NAME] = ""  if env[SCRIPT_NAME] == "/"

        env.update(
          RACK_INPUT        => $stdin,
          RACK_ERRORS       => $stderr,
          RACK_URL_SCHEME   => ["yes", "on", "1"].include?(ENV[HTTPS]) ? "https" : "http"
        )

        env[QUERY_STRING] ||= ""
        env[REQUEST_PATH] ||= "/"

        status, headers, body = app.call(env)
        begin
          send_headers status, headers
          send_body body
        ensure
          body.close  if body.respond_to? :close
        end
      end

      def self.send_headers(status, headers)
        $stdout.print "Status: #{status}\r\n"
        headers.each { |k, vs|
          vs.split("\n").each { |v|
            $stdout.print "#{k}: #{v}\r\n"
          }
        }
        $stdout.print "\r\n"
        $stdout.flush
      end

      def self.send_body(body)
        body.each { |part|
          $stdout.print part
          $stdout.flush
        }
      end
    end

    register :cgi, CGI
  end
end
