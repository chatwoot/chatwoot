# frozen_string_literal: true

module Seahorse
  module Client
    module Http
      class AsyncResponse < Seahorse::Client::Http::Response

        def initialize(options = {})
          super
        end

        def signal_headers(headers)
          # H2 headers arrive as array of pair
          hash = headers.inject({}) do |h, pair|
            key, value = pair
            h[key] = value
            h
          end
          @status_code = hash[":status"].to_i
          @headers = Headers.new(hash)
          emit(:headers, @status_code, @headers)
        end

        def signal_done(options = {})
          # H2 only has header and body
          # ':status' header will be sent back
          if options.keys.sort == [:body, :headers]
            signal_headers(options[:headers])
            signal_data(options[:body])
            signal_done
          elsif options.empty?
            @body.rewind if @body.respond_to?(:rewind)
            @done = true
            emit(:done)
          else
            msg = "options must be empty or must contain :headers and :body"
            raise ArgumentError, msg
          end
        end

      end
    end
  end
end
