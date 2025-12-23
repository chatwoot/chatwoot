# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/prepend_supportability'

module NewRelic
  module Agent
    module Instrumentation
      module ActiveRecordPrepend
        ACTIVE_RECORD = 'ActiveRecord'.freeze

        module BaseExtensions
          if RUBY_VERSION < '2.7.0'
            def save(*args, &blk)
              ::NewRelic::Agent.with_database_metric_name(self.class.name, nil, ACTIVE_RECORD) do
                super
              end
            end

            def save!(*args, &blk)
              ::NewRelic::Agent.with_database_metric_name(self.class.name, nil, ACTIVE_RECORD) do
                super
              end
            end

          else
            def save(*args, **kwargs, &blk)
              ::NewRelic::Agent.with_database_metric_name(self.class.name, nil, ACTIVE_RECORD) do
                super
              end
            end

            def save!(*args, **kwargs, &blk)
              ::NewRelic::Agent.with_database_metric_name(self.class.name, nil, ACTIVE_RECORD) do
                super
              end
            end

          end
        end

        module BaseExtensions516
          # In ActiveRecord v5.0.0 through v5.1.5, touch() will call
          # update_all() and cause us to record a transaction.
          # Starting in v5.1.6, this call no longer happens. We'll
          # have to set the database metrics explicitly now.
          #
          if RUBY_VERSION < '2.7.0'
            def touch(*args, **kwargs, &blk)
              ::NewRelic::Agent.with_database_metric_name(self.class.name, nil, ACTIVE_RECORD) do
                super
              end
            end
          else
            def touch(*args, **kwargs, &blk)
              ::NewRelic::Agent.with_database_metric_name(self.class.name, nil, ACTIVE_RECORD) do
                super
              end
            end
          end
        end

        module RelationExtensions
          def update_all(*args, &blk)
            ::NewRelic::Agent.with_database_metric_name(self.name, nil, ACTIVE_RECORD) do
              super
            end
          end

          def delete_all(*args, &blk)
            ::NewRelic::Agent.with_database_metric_name(self.name, nil, ACTIVE_RECORD) do
              super
            end
          end

          def destroy_all(*args, &blk)
            ::NewRelic::Agent.with_database_metric_name(self.name, nil, ACTIVE_RECORD) do
              super
            end
          end

          def calculate(*args, &blk)
            ::NewRelic::Agent.with_database_metric_name(self.name, nil, ACTIVE_RECORD) do
              super
            end
          end

          def pluck(*args, &blk)
            ::NewRelic::Agent.with_database_metric_name(self.name, nil, ACTIVE_RECORD) do
              super
            end
          end
        end
      end
    end
  end
end
