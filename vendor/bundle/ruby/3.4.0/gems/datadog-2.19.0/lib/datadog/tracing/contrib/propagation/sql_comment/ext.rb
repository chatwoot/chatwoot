# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Propagation
        module SqlComment
          module Ext
            ENV_DBM_PROPAGATION_MODE = 'DD_DBM_PROPAGATION_MODE'

            # The default mode for sql comment propagation
            DISABLED = 'disabled'

            # The `service` mode propagates service configuration
            SERVICE = 'service'

            # The `full` mode propagates service configuration + trace context
            FULL = 'full'

            # The value should be `true` when `full` mode
            TAG_DBM_TRACE_INJECTED = '_dd.dbm_trace_injected'

            # Database service/sql span service (i.e. the service executing the actual query)
            #
            # If fake services are disabled:
            #   This value will be the same as the parent service
            #
            # If fake services are enabled:
            #   This value is NOT the same as the parent service
            #
            # This should NOT be overridden by peer.service.
            KEY_DATABASE_SERVICE = 'dddbs'

            # The global service environment (e.g. DD_ENV)
            KEY_ENVIRONMENT = 'dde'

            # The global service name (e.g. DD_SERVICE)
            KEY_PARENT_SERVICE = 'ddps'

            # The global service version (e.g. DD_VERSION)
            KEY_VERSION = 'ddpv'

            # The hostname of the database server, as provided to the database client upon instantiation.
            # @see Datadog::Tracing::Metadata::Ext::TAG_PEER_HOSTNAME
            KEY_HOSTNAME = 'ddh'

            # @see Datadog::Tracing::Contrib::Ext::DB::TAG_INSTANCE
            KEY_DB_NAME = 'dddb'

            # Users can use this attribute to specify the identity of the dependency/database they are connecting to.
            # We should grab this attribute only if the user is EXPLICITLY specifying it.
            # @see Datadog::Tracing::Metadata::Ext::TAG_PEER_SERVICE
            KEY_PEER_SERVICE = 'ddprs'

            KEY_TRACEPARENT = 'traceparent'
          end
        end
      end
    end
  end
end
