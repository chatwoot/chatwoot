# frozen_string_literal: true
require_relative '../json_serialization'

module Puma
  module App
    # Check out {#call}'s source code to see what actions this web application
    # can respond to.
    class Status
      OK_STATUS = '{ "status": "ok" }'.freeze

      # @param launcher [::Puma::Launcher]
      # @param token [String, nil] the token used for authentication
      #
      def initialize(launcher, token = nil)
        @launcher = launcher
        @auth_token = token
      end

      # most commands call methods in `::Puma::Launcher` based on command in
      # `env['PATH_INFO']`
      def call(env)
        unless authenticate(env)
          return rack_response(403, 'Invalid auth token', 'text/plain')
        end

        # resp_type is processed by following case statement, return
        # is a number (status) or a string used as the body of a 200 response
        resp_type =
          case env['PATH_INFO'][/\/([^\/]+)$/, 1]
          when 'stop'
            @launcher.stop ; 200

          when 'halt'
            @launcher.halt ; 200

          when 'restart'
            @launcher.restart ; 200

          when 'phased-restart'
            @launcher.phased_restart ? 200 : 404

          when 'refork'
            @launcher.refork ? 200 : 404

          when 'reload-worker-directory'
            @launcher.send(:reload_worker_directory) ? 200 : 404

          when 'gc'
            GC.start ; 200

          when 'gc-stats'
            Puma::JSONSerialization.generate GC.stat

          when 'stats'
            Puma::JSONSerialization.generate @launcher.stats

          when 'thread-backtraces'
            backtraces = []
            @launcher.thread_status do |name, backtrace|
              backtraces << { name: name, backtrace: backtrace }
            end
            Puma::JSONSerialization.generate backtraces

          else
            return rack_response(404, "Unsupported action", 'text/plain')
          end

        case resp_type
        when String
          rack_response 200, resp_type
        when 200
          rack_response 200, OK_STATUS
        when 404
          str = env['PATH_INFO'][/\/(\S+)/, 1].tr '-', '_'
          rack_response 404, "{ \"error\": \"#{str} not available\" }"
        end
      end

      private

      def authenticate(env)
        return true unless @auth_token
        env['QUERY_STRING'].to_s.split('&;').include? "token=#{@auth_token}"
      end

      def rack_response(status, body, content_type='application/json')
        headers = {
          'content-type' => content_type,
          'content-length' => body.bytesize.to_s
        }

        [status, headers, [body]]
      end
    end
  end
end
