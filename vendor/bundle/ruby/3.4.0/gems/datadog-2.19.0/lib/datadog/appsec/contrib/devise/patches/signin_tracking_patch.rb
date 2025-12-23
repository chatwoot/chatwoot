# frozen_string_literal: true

require_relative '../ext'
require_relative '../configuration'
require_relative '../data_extractor'

module Datadog
  module AppSec
    module Contrib
      module Devise
        module Patches
          # A patch for Devise::Authenticatable strategy with tracking functionality
          module SigninTrackingPatch
            def validate(resource, &block)
              result = super

              return result unless AppSec.enabled?
              return result if @_datadog_appsec_skip_track_login_event
              return result unless Configuration.auto_user_instrumentation_enabled?
              return result unless AppSec.active_context

              context = AppSec.active_context
              if context.trace.nil? || context.span.nil?
                Datadog.logger.debug { 'AppSec: unable to track signin events, due to missing trace or span' }
                return result
              end

              context.trace.keep!

              if result
                record_successful_signin(context, resource)
                Instrumentation.gateway.push('appsec.events.user_lifecycle', Ext::EVENT_LOGIN_SUCCESS)

                return result
              end

              record_failed_signin(context, resource)
              Instrumentation.gateway.push('appsec.events.user_lifecycle', Ext::EVENT_LOGIN_FAILURE)

              result
            end

            private

            def record_successful_signin(context, resource)
              extractor = DataExtractor.new(mode: Configuration.auto_user_instrumentation_mode)

              id = extractor.extract_id(resource)
              login = extractor.extract_login(authentication_hash) || extractor.extract_login(resource)

              if id
                context.span[Ext::TAG_USR_ID] ||= id
                context.span[Ext::TAG_DD_USR_ID] = id
              end

              context.span[Ext::TAG_LOGIN_SUCCESS_USR_LOGIN] ||= login
              context.span[Ext::TAG_LOGIN_SUCCESS_TRACK] = 'true'
              context.span[Ext::TAG_DD_USR_LOGIN] = login
              context.span[Ext::TAG_DD_LOGIN_SUCCESS_MODE] = Configuration.auto_user_instrumentation_mode

              # NOTE: We don't have a way to make one-shot receivers for events,
              #       and because of that we will trigger an additional event even
              #       if it was already done via the SDK
              AppSec::Instrumentation.gateway.push(
                'identity.set_user', AppSec::Instrumentation::Gateway::User.new(id, login)
              )
            end

            def record_failed_signin(context, resource)
              extractor = DataExtractor.new(mode: Configuration.auto_user_instrumentation_mode)

              context.span[Ext::TAG_LOGIN_FAILURE_TRACK] = 'true'
              context.span[Ext::TAG_DD_LOGIN_FAILURE_MODE] = Configuration.auto_user_instrumentation_mode

              unless resource
                login = extractor.extract_login(authentication_hash)

                context.span[Ext::TAG_DD_USR_LOGIN] = login
                context.span[Ext::TAG_LOGIN_FAILURE_USR_LOGIN] ||= login
                context.span[Ext::TAG_LOGIN_FAILURE_USR_EXISTS] ||= 'false'

                return
              end

              id = extractor.extract_id(resource)
              login = extractor.extract_login(authentication_hash) || extractor.extract_login(resource)

              if id
                context.span[Ext::TAG_DD_USR_ID] = id
                context.span[Ext::TAG_LOGIN_FAILURE_USR_ID] ||= id
              end

              context.span[Ext::TAG_DD_USR_LOGIN] = login
              context.span[Ext::TAG_LOGIN_FAILURE_USR_LOGIN] ||= login
              context.span[Ext::TAG_LOGIN_FAILURE_USR_EXISTS] ||= 'true'
            end
          end
        end
      end
    end
  end
end
