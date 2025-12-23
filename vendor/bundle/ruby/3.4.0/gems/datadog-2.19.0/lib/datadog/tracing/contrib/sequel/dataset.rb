# frozen_string_literal: true

require_relative '../../metadata/ext'
require_relative '../analytics'
require_relative 'ext'
require_relative 'utils'

module Datadog
  module Tracing
    module Contrib
      module Sequel
        # Adds instrumentation to Sequel::Dataset
        module Dataset
          def self.included(base)
            base.prepend(InstanceMethods)
          end

          # Instance methods for instrumenting Sequel::Dataset
          module InstanceMethods
            def execute(sql, options = ::Sequel::OPTS, &block)
              trace_execute(proc { super(sql, options, &block) }, sql, options, &block)
            end

            def execute_ddl(sql, options = ::Sequel::OPTS, &block)
              trace_execute(proc { super(sql, options, &block) }, sql, options, &block)
            end

            def execute_dui(sql, options = ::Sequel::OPTS, &block)
              trace_execute(proc { super(sql, options, &block) }, sql, options, &block)
            end

            def execute_insert(sql, options = ::Sequel::OPTS, &block)
              trace_execute(proc { super(sql, options, &block) }, sql, options, &block)
            end

            private

            def trace_execute(super_method, sql, options, &block)
              opts = Utils.parse_opts(sql, options, db.opts, self)
              response = nil

              Tracing.trace(Ext::SPAN_QUERY) do |span|
                span.service =  Datadog.configuration_for(db, :service_name) \
                                || Datadog.configuration.tracing[:sequel][:service_name] \
                                || Contrib::SpanAttributeSchema.fetch_service_name(
                                  '',
                                  adapter_name
                                )
                span.resource = opts[:query]
                span.type = Tracing::Metadata::Ext::SQL::TYPE
                Utils.set_common_tags(span, db)
                span.set_tag(Ext::TAG_DB_VENDOR, adapter_name)
                span.set_tag(Ext::TAG_PREPARED_NAME, opts[:prepared_name]) if opts[:prepared_name]
                response = super_method.call(sql, options, &block)
              end
              response
            end

            def adapter_name
              Utils.adapter_name(db)
            end
          end
        end
      end
    end
  end
end
