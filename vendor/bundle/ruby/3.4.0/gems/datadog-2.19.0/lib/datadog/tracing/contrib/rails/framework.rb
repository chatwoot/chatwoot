# frozen_string_literal: true

require_relative '../action_cable/integration'
require_relative '../action_mailer/integration'
require_relative '../action_pack/integration'
require_relative '../action_view/integration'
require_relative '../active_record/integration'
require_relative '../active_support/integration'
require_relative '../grape/endpoint'
require_relative '../lograge/integration'
require_relative 'ext'
require_relative '../../../core/contrib/rails/utils'
require_relative '../semantic_logger/integration'

module Datadog
  module Tracing
    module Contrib
      # Instrument Rails.
      module Rails
        # Rails framework code, used to essentially:
        # - handle configuration entries which are specific to Datadog tracing
        # - instrument parts of the framework when needed
        module Framework
          # After the Rails application finishes initializing, we configure the Rails
          # integration and all its sub-components with the application information
          # available.
          # We do this after the initialization because not all the information we
          # require is available before then.
          def self.setup
            # NOTE: #configure has the side effect of rebuilding trace components.
            #       During a typical Rails application lifecycle, we will see trace
            #       components initialized twice because of this. This is necessary
            #       because key configuration is not available until after the Rails
            #       application has fully loaded, and some of this configuration is
            #       used to reconfigure tracer components with Rails-sourced defaults.
            #       This is a trade-off we take to get nice defaults.
            Datadog.configure do |datadog_config|
              rails_config = datadog_config.tracing[:rails]

              # By default, default service would be guessed from the script
              # being executed, but here we know better, get it from Rails config.
              # Don't set this if service has been explicitly provided by the user.
              if datadog_config.service_without_fallback.nil?
                datadog_config.service = rails_config[:service_name] || Core::Contrib::Rails::Utils.app_name
              end

              activate_rack!(datadog_config, rails_config)
              activate_action_cable!(datadog_config, rails_config)
              activate_action_mailer!(datadog_config, rails_config)
              activate_active_support!(datadog_config, rails_config)
              activate_action_pack!(datadog_config, rails_config)
              activate_action_view!(datadog_config, rails_config)
              activate_active_job!(datadog_config, rails_config)
              activate_active_record!(datadog_config, rails_config)
              activate_lograge!(datadog_config, rails_config)
              activate_semantic_logger!(datadog_config, rails_config)
            end
          end

          def self.activate_rack!(datadog_config, rails_config)
            datadog_config.tracing.instrument(
              :rack,
              application: ::Rails.application,
              service_name: rails_config[:service_name],
              middleware_names: rails_config[:middleware_names],
              distributed_tracing: rails_config[:distributed_tracing],
              request_queuing: rails_config[:request_queuing]
            )
          end

          def self.activate_active_support!(datadog_config, rails_config)
            return unless defined?(::ActiveSupport)

            datadog_config.tracing.instrument(:active_support)
          end

          def self.activate_action_cable!(datadog_config, rails_config)
            return unless defined?(::ActionCable)

            datadog_config.tracing.instrument(:action_cable)
          end

          def self.activate_action_mailer!(datadog_config, rails_config)
            return unless defined?(::ActionMailer)

            datadog_config.tracing.instrument(
              :action_mailer,
              service_name: rails_config[:service_name]
            )
          end

          def self.activate_action_pack!(datadog_config, rails_config)
            return unless defined?(::ActionPack)

            datadog_config.tracing.instrument(
              :action_pack,
              service_name: rails_config[:service_name]
            )
          end

          def self.activate_action_view!(datadog_config, rails_config)
            return unless defined?(::ActionView)

            datadog_config.tracing.instrument(
              :action_view,
              service_name: rails_config[:service_name]
            )
          end

          def self.activate_active_job!(datadog_config, rails_config)
            return unless defined?(::ActiveJob)

            datadog_config.tracing.instrument(
              :active_job,
              service_name: rails_config[:service_name]
            )
          end

          def self.activate_active_record!(datadog_config, rails_config)
            return unless defined?(::ActiveRecord)

            datadog_config.tracing.instrument(:active_record)
          end

          def self.activate_lograge!(datadog_config, rails_config)
            return unless defined?(::Lograge)

            if datadog_config.tracing.log_injection
              datadog_config.tracing.instrument(
                :lograge
              )
            end
          end

          def self.activate_semantic_logger!(datadog_config, rails_config)
            return unless defined?(::SemanticLogger)

            if datadog_config.tracing.log_injection
              datadog_config.tracing.instrument(
                :semantic_logger
              )
            end
          end
        end
      end
    end
  end
end
