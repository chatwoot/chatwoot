# frozen_string_literal: true

require_relative '../ext'
require_relative '../configuration'
require_relative '../data_extractor'

module Datadog
  module AppSec
    module Contrib
      module Devise
        module Patches
          # A patch for Devise::RegistrationsController with tracking functionality
          module SignupTrackingPatch
            def create
              return super unless AppSec.enabled?
              return super unless Configuration.auto_user_instrumentation_enabled?
              return super unless AppSec.active_context

              super do |resource|
                context = AppSec.active_context

                if context.trace.nil? || context.span.nil?
                  Datadog.logger.debug { 'AppSec: unable to track signup events, due to missing trace or span' }
                  next yield(resource) if block_given?
                end

                next yield(resource) if resource.new_record? && block_given?

                context.trace.keep!
                record_successful_signup(context, resource)
                Instrumentation.gateway.push('appsec.events.user_lifecycle', Ext::EVENT_SIGNUP)

                yield(resource) if block_given?
              end
            end

            private

            def record_successful_signup(context, resource)
              extractor = DataExtractor.new(mode: Configuration.auto_user_instrumentation_mode)

              id = extractor.extract_id(resource)
              login = extractor.extract_login(resource_params) || extractor.extract_login(resource)

              context.span[Ext::TAG_SIGNUP_TRACK] = 'true'
              context.span[Ext::TAG_DD_USR_LOGIN] = login
              context.span[Ext::TAG_SIGNUP_USR_LOGIN] ||= login
              context.span[Ext::TAG_DD_SIGNUP_MODE] = Configuration.auto_user_instrumentation_mode

              if id
                context.span[Ext::TAG_DD_USR_ID] = id

                id_tag = resource.active_for_authentication? ? Ext::TAG_USR_ID : Ext::TAG_SIGNUP_USR_ID
                context.span[id_tag] ||= id
              end

              # NOTE: We don't have a way to make one-shot receivers for events,
              #       and because of that we will trigger an additional event even
              #       if it was already done via the SDK
              AppSec::Instrumentation.gateway.push(
                'identity.set_user', AppSec::Instrumentation::Gateway::User.new(id, login)
              )
            end
          end
        end
      end
    end
  end
end
