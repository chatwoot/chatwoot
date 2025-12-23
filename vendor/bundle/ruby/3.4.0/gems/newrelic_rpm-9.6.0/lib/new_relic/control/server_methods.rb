# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  class Control
    # Structs holding info for the remote server and proxy server
    class Server < Struct.new(:name, :port) # :nodoc:
      def to_s; "#{name}:#{port}"; end
    end

    # Contains methods that deal with connecting to the server
    module ServerMethods
      def server
        @remote_server ||= server_from_host(nil)
      end

      # the server we should contact for api requests, like uploading
      # deployments and the like
      def api_server
        @api_server ||= NewRelic::Control::Server.new(Agent.config[:api_host], Agent.config[:api_port])
      end

      def server_from_host(hostname = nil)
        NewRelic::Control::Server.new(hostname || Agent.config[:host], Agent.config[:port])
      end
    end

    include ServerMethods
  end
end
