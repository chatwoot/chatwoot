# frozen_string_literal: true

module Datadog
  module Tracing
    module Metadata
      # Trace and span tags that represent meta information
      # regarding the trace. These fields are normally only used
      # internally, and can have special meaning to downstream
      # trace processing.
      # @public_api
      module Ext
        # Name of package that was instrumented
        TAG_COMPONENT = 'component'
        # Type of operation being performed (e.g. )
        TAG_OPERATION = 'operation'
        # Hostname of external service interacted with
        #
        # This tag also doesn't strictly need to be a “hostname”. It can be a raw IP address and in some cases it
        # can even be a unix domain socket (i.e. postgres client setting host=/var/run/postgres).
        # It should be whatever the client uses to point at the server it’s trying to talk to.
        TAG_PEER_HOSTNAME = 'peer.hostname'
        # Name of external service that performed the work
        TAG_PEER_SERVICE = 'peer.service'

        TAG_KIND = 'span.kind'

        # Set this tag to `1.0` if the span is a Service Entry span.
        TAG_TOP_LEVEL = '_dd.top_level'

        # Set to `1.0` if profiling is enabled together with tracing, and `0.0` otherwise
        # See Datadog-internal "RFC: Identifying which spans have profiling enabled " for details
        TAG_PROFILING_ENABLED = '_dd.profiling.enabled'

        TAG_APM_ENABLED = '_dd.apm.enabled'

        # Defines constants for trace analytics
        # @public_api
        module Analytics
          DEFAULT_SAMPLE_RATE = 1.0
          TAG_ENABLED = 'analytics.enabled'
          TAG_MEASURED = '_dd.measured'
          TAG_SAMPLE_RATE = '_dd1.sr.eausr'
        end

        module AppTypes
          TYPE_WEB = 'web'
          TYPE_DB = 'db'
          TYPE_CACHE = 'cache'
          TYPE_WORKER = 'worker'
          TYPE_CUSTOM = 'custom'
        end

        # @public_api
        # Tags related to distributed tracing
        module Distributed
          # What mechanism was used to make this trace's sampling decision.
          # @see Datadog::Tracing::Sampling::Ext::Mechanism
          TAG_DECISION_MAKER = '_dd.p.dm'

          # Bitmask for which product generated an event. E.g.: 2 for an AppSec event.
          TAG_TRACE_SOURCE = '_dd.p.ts'

          TAG_ORIGIN = '_dd.origin'
          TAG_SAMPLING_PRIORITY = '_sampling_priority_v1'

          TAG_DD_PARENT_ID = '_dd.parent_id'
          DD_PARENT_ID_DEFAULT = '0000000000000000'

          # Trace tags with this prefix will propagate from a trace through distributed tracing.
          # Distributed headers tags with this prefix will be injected into the active trace.
          TAGS_PREFIX = '_dd.p.'

          # The distributed tag to carry hex encoded high order 64 bits of 127 bits trace id during
          # the context restricted with 64 bits. Such as, Datadog propagation and messagepack encoding
          TID = 'tid'
          TAG_TID = TAGS_PREFIX + TID
        end

        # @public_api
        module Errors
          STATUS = 1
          TAG_MSG = 'error.message'
          TAG_STACK = 'error.stack'
          TAG_TYPE = 'error.type'
        end

        # @public_api
        module HTTP
          ERROR_RANGE = (500...600).freeze
          TAG_BASE_URL = 'http.base_url'
          TAG_METHOD = 'http.method'
          TAG_STATUS_CODE = 'http.status_code'
          TAG_USER_AGENT = 'http.useragent'
          TAG_URL = 'http.url'
          TAG_ROUTE = 'http.route'
          TAG_ROUTE_PATH = 'http.route.path'
          TYPE_INBOUND = AppTypes::TYPE_WEB.freeze
          TYPE_OUTBOUND = 'http'
          TYPE_PROXY = 'proxy'
          TYPE_TEMPLATE = 'template'
          TAG_CLIENT_IP = 'http.client_ip'
          HEADER_USER_AGENT = 'User-Agent'

          # General header functionality
          module Headers
            module_function

            INVALID_TAG_CHARACTERS = %r{[^a-z0-9_\-:./]}.freeze

            # Normalizes an HTTP header string into a valid tag string.
            #
            # By default, tags cannot create nested span tag levels:
            # `allow_nested` allows you to override this behavior.
            def to_tag(name, allow_nested: false)
              # Tag normalization based on: https://docs.datadoghq.com/getting_started/tagging/#defining-tags.
              #
              # Only the following characters are accepted.
              #  * Alphanumerics
              #  * Underscores
              #  * Minuses
              #  * Colons
              #  * Periods
              #  * Slashes
              #
              # All other characters are replaced with an underscore.
              tag = name.to_s.strip
              tag.downcase!
              tag.gsub!(INVALID_TAG_CHARACTERS, '_')

              # Additional HTTP header normalization.
              #
              # Periods are replaced with an underscore.
              tag.tr!('.', '_') unless allow_nested
              tag
            end
          end

          # Request headers
          module RequestHeaders
            PREFIX = 'http.request.headers'

            module_function

            def to_tag(name)
              "#{PREFIX}.#{Headers.to_tag(name)}"
            end
          end

          # Response headers
          module ResponseHeaders
            PREFIX = 'http.response.headers'

            module_function

            def to_tag(name)
              "#{PREFIX}.#{Headers.to_tag(name)}"
            end
          end
        end

        # @public_api
        module NET
          TAG_HOSTNAME = '_dd.hostname'
          TAG_TARGET_HOST = 'out.host'
          TAG_TARGET_PORT = 'out.port'
          TAG_DESTINATION_NAME = 'network.destination.name'
          TAG_DESTINATION_PORT = 'network.destination.port'
        end

        # @public_api
        module Sampling
          TAG_AGENT_RATE = '_dd.agent_psr'

          # If rule sampling is applied to a span, set this metric the sample rate configured for that rule.
          # This should be done regardless of sampling outcome.
          TAG_RULE_SAMPLE_RATE = '_dd.rule_psr'

          # If rate limiting is checked on a span, set this metric the effective rate limiting rate applied.
          # This should be done regardless of rate limiting outcome.
          TAG_RATE_LIMITER_RATE = '_dd.limit_psr'

          TAG_SAMPLE_RATE = '_sample_rate'
        end

        # @public_api
        module SQL
          TYPE = 'sql'
          TAG_QUERY = 'sql.query'
        end

        # @public_api
        module SpanKind
          TAG_PROXY = 'proxy'
          TAG_SERVER = 'server'
          TAG_CLIENT = 'client'
          TAG_PRODUCER = 'producer'
          TAG_CONSUMER = 'consumer'
          TAG_INTERNAL = 'internal'
        end

        # @public_api
      end
    end
  end
end
