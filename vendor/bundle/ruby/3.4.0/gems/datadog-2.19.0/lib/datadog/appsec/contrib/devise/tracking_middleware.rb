# frozen_string_literal: true

require_relative 'ext'
require_relative '../../anonymizer'

module Datadog
  module AppSec
    module Contrib
      module Devise
        # A Rack middleware capable of tracking currently signed user
        class TrackingMiddleware
          WARDEN_KEY = 'warden'
          SESSION_ID_KEY = 'session_id'

          def initialize(app)
            @app = app
            @devise_session_scope_keys = {}
          end

          def call(env)
            return @app.call(env) unless AppSec.enabled?
            return @app.call(env) unless Configuration.auto_user_instrumentation_enabled?
            return @app.call(env) unless AppSec.active_context

            unless env.key?(WARDEN_KEY)
              Datadog.logger.debug { 'AppSec: unable to track requests, due to missing warden manager' }
              return @app.call(env)
            end

            context = AppSec.active_context
            if context.trace.nil? || context.span.nil?
              Datadog.logger.debug { 'AppSec: unable to track requests, due to missing trace or span' }
              return @app.call(env)
            end

            # NOTE: Rails session id will be set for unauthenticated users as well,
            #       so we need to make sure we are tracking only authenticated users.
            id = transform(extract_id(env[WARDEN_KEY]))
            session_id = env[WARDEN_KEY].raw_session[SESSION_ID_KEY] if id

            if id
              # NOTE: There is no option to set session id without setting user id via SDK.
              unless context.span.has_tag?(Ext::TAG_USR_ID) && context.span.has_tag?(Ext::TAG_SESSION_ID)
                user_id = context.span[Ext::TAG_USR_ID] || id
                user_session_id = context.span[Ext::TAG_SESSION_ID] || session_id

                # FIXME: The current implementation of event arguments is forsing us
                #        to bloat User class, and pass nil-value instead of skip
                #        passing them at first place.
                #        This is a temporary situation until we refactor events model.
                AppSec::Instrumentation.gateway.push(
                  'identity.set_user', AppSec::Instrumentation::Gateway::User.new(user_id, nil, user_session_id)
                )
              end

              context.span[Ext::TAG_USR_ID] ||= id
              context.span[Ext::TAG_DD_USR_ID] = id
              context.span[Ext::TAG_DD_COLLECTION_MODE] ||= Configuration.auto_user_instrumentation_mode
            end

            @app.call(env)
          end

          private

          def extract_id(warden)
            session_serializer = warden.session_serializer

            key = session_key_for(session_serializer, ::Devise.default_scope)
            id = session_serializer.session[key]&.dig(0, 0)

            return id if ::Devise.mappings.size == 1
            return "#{::Devise.default_scope}:#{id}" if id

            ::Devise.mappings.each_key do |scope|
              next if scope == ::Devise.default_scope

              key = session_key_for(session_serializer, scope)
              id = session_serializer.session[key]&.dig(0, 0)

              return "#{scope}:#{id}" if id
            end

            nil
          end

          def session_key_for(session_serializer, scope)
            @devise_session_scope_keys[scope] ||= session_serializer.key_for(scope)
          end

          def transform(value)
            return if value.nil?
            return value.to_s unless anonymize?

            Anonymizer.anonymize(value.to_s)
          end

          def anonymize?
            Configuration.auto_user_instrumentation_mode ==
              AppSec::Configuration::Settings::ANONYMIZATION_AUTO_USER_INSTRUMENTATION_MODE
          end
        end
      end
    end
  end
end
