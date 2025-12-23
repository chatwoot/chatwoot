# frozen_string_literal: true

require_relative '../../metadata/ext'
require_relative '../utils/database'

module Datadog
  module Tracing
    module Contrib
      module Sequel
        # General purpose functions for Sequel
        module Utils
          class << self
            # Ruby database connector library
            #
            # e.g. adapter:mysql2 (database:mysql), adapter:jdbc (database:postgres)
            def adapter_name(database)
              scheme = database.adapter_scheme.to_s

              if scheme == 'jdbc'
                # The subtype is more important in this case,
                # otherwise all database adapters will be 'jdbc'.
                database_type(database)
              else
                Contrib::Utils::Database.normalize_vendor(scheme)
              end
            end

            # Database engine
            #
            # e.g. database:mysql (adapter:mysql2), database:postgres (adapter:jdbc)
            def database_type(database)
              Contrib::Utils::Database.normalize_vendor(database.database_type.to_s)
            end

            def parse_opts(sql, opts, db_opts, dataset = nil)
              # Prepared statements don't provide their sql query in the +sql+ parameter.
              if !sql.is_a?(String) && (dataset && dataset.respond_to?(:prepared_sql) &&
                (resolved_sql = dataset.prepared_sql))
                # The dataset contains the resolved SQL query and prepared statement name.
                prepared_name = dataset.prepared_statement_name
                sql = resolved_sql
              end

              {
                name: opts[:type],
                query: sql,
                prepared_name: prepared_name,
                database: db_opts[:database],
                host: db_opts[:host]
              }
            end

            def set_common_tags(span, db)
              # Tag original global service name if not used
              if span.service != Datadog.configuration.service
                span.set_tag(Tracing::Contrib::Ext::Metadata::TAG_BASE_SERVICE, Datadog.configuration.service)
              end

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_QUERY)

              # TODO: Extract host for Sequel with JDBC. The easiest way seem to be through
              # TODO: the database URI. Unfortunately, JDBC URIs do not work with `URI.parse`.
              # host, _port = extract_host_port_from_uri(db.uri)
              # span.set_tag(Tracing::Metadata::Ext::TAG_DESTINATION_NAME, host)
              span.set_tag(Tracing::Metadata::Ext::NET::TAG_DESTINATION_NAME, db.opts[:host]) if db.opts[:host]

              # Set analytics sample rate
              Contrib::Analytics.set_sample_rate(span, analytics_sample_rate) if analytics_enabled?
            end

            private

            def datadog_configuration
              Datadog.configuration.tracing[:sequel]
            end

            def analytics_enabled?
              Contrib::Analytics.enabled?(datadog_configuration[:analytics_enabled])
            end

            def analytics_sample_rate
              datadog_configuration[:analytics_sample_rate]
            end
          end
        end
      end
    end
  end
end
