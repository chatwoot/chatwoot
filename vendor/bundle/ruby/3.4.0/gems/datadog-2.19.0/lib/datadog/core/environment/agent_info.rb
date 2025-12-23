# frozen_string_literal: true

module Datadog
  module Core
    module Environment
      # Retrieves the agent's `/info` endpoint data.
      # This data can be used to determine the capabilities of the local Datadog agent.
      #
      # @example Example response payload
      #   {
      #     "version" : "7.57.2",
      #     "git_commit" : "38ba0c7",
      #     "endpoints" : [ "/v0.4/traces", "/v0.4/services", "/v0.7/traces", "/v0.7/config" ],
      #     "client_drop_p0s" : true,
      #     "span_meta_structs" : true,
      #     "long_running_spans" : true,
      #     "evp_proxy_allowed_headers" : [ "Content-Type", "Accept-Encoding", "Content-Encoding", "User-Agent" ],
      #     "config" : {
      #       "default_env" : "none",
      #       "target_tps" : 10,
      #       "max_eps" : 200,
      #       "receiver_port" : 8126,
      #       "receiver_socket" : "/var/run/datadog/apm.socket",
      #       "connection_limit" : 0,
      #       "receiver_timeout" : 0,
      #       "max_request_bytes" : 26214400,
      #       "statsd_port" : 8125,
      #       "analyzed_spans_by_service" : { },
      #       "obfuscation" : {
      #         "elastic_search" : true,
      #         "mongo" : true,
      #         "sql_exec_plan" : false,
      #         "sql_exec_plan_normalize" : false,
      #         "http" : {
      #           "remove_query_string" : false,
      #           "remove_path_digits" : false
      #         },
      #         "remove_stack_traces" : false,
      #         "redis" : {
      #           "Enabled" : true,
      #           "RemoveAllArgs" : false
      #         },
      #         "memcached" : {
      #           "Enabled" : true,
      #           "KeepCommand" : false
      #         }
      #       }
      #     },
      #     "peer_tags" : null
      #   }
      #
      # @see https://github.com/DataDog/datadog-agent/blob/f07df0a3c1fca0c83b5a15f553bd994091b0c8ac/pkg/trace/api/info.go#L20
      class AgentInfo
        attr_reader :agent_settings, :logger

        def initialize(agent_settings, logger: Datadog.logger)
          @agent_settings = agent_settings
          @logger = logger
          @client = Remote::Transport::HTTP.root(agent_settings: agent_settings, logger: logger)
        end

        # Fetches the information from the agent.
        # @return [Datadog::Core::Remote::Transport::HTTP::Negotiation::Response] the response from the agent
        # @return [nil] if an error occurred while fetching the information
        def fetch
          res = @client.send_info
          return unless res.ok?

          res
        end

        def ==(other)
          other.is_a?(self.class) && other.agent_settings == agent_settings
        end
      end
    end
  end
end
