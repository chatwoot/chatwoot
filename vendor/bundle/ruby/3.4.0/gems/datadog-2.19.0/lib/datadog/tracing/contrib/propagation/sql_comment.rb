# frozen_string_literal: true

require_relative 'sql_comment/comment'
require_relative 'sql_comment/ext'

require_relative '../../distributed/trace_context'

module Datadog
  module Tracing
    module Contrib
      module Propagation
        # Implements sql comment propagation related contracts.
        module SqlComment
          def self.annotate!(span_op, mode)
            return unless mode.enabled?

            span_op.set_tag(Ext::TAG_DBM_TRACE_INJECTED, true) if mode.full?
          end

          # Inject span_op and trace_op instead of TraceDigest to improve memory usage
          # for `disabled` and `service` mode
          def self.prepend_comment(sql, span_op, trace_op, mode)
            return sql unless mode.enabled?

            config = Datadog.configuration

            parent_service = config.service
            peer_service = span_op.get_tag(Tracing::Metadata::Ext::TAG_PEER_SERVICE)

            tags = {
              Ext::KEY_ENVIRONMENT => config.env,
              Ext::KEY_PARENT_SERVICE => parent_service,
              Ext::KEY_VERSION => config.version,
              Ext::KEY_HOSTNAME => span_op.get_tag(Tracing::Metadata::Ext::TAG_PEER_HOSTNAME),
              Ext::KEY_DB_NAME => span_op.get_tag(Contrib::Ext::DB::TAG_INSTANCE),
              Ext::KEY_PEER_SERVICE => peer_service,
            }

            db_service = peer_service || span_op.service
            if parent_service != db_service # Only set if it's different from parent_service; otherwise it's redundant
              tags[Ext::KEY_DATABASE_SERVICE] = db_service
            end

            if mode.full?
              # When tracing is disabled, trace_operation is a dummy object that does not contain data to build traceparent
              if config.tracing.enabled
                tags[Ext::KEY_TRACEPARENT] =
                  Tracing::Distributed::TraceContext.new(fetcher: nil).send(:build_traceparent, trace_op.to_digest)
              else
                Datadog.logger.warn(
                  'Sql comment propagation with `full` mode is aborted, because tracing is disabled. '\
                  'Please set `Datadog.configuration.tracing.enabled = true` to continue.'
                )
              end
            end

            if mode.append?
              "#{sql} #{Comment.new(tags)}"
            else
              "#{Comment.new(tags)} #{sql}"
            end
          end
        end
      end
    end
  end
end
