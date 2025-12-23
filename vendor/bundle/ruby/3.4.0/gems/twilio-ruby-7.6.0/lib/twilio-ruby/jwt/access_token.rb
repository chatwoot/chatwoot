# frozen_string_literal: true

module Twilio
  module JWT
    module AccessTokenGrant
      def _key
        raise NotImplementedError
      end

      def _generate_payload
        raise NotImplementedError
      end
    end

    class AccessToken < BaseJWT
      attr_accessor :account_sid,
                    :signing_key_id,
                    :secret,
                    :identity,
                    :grants,
                    :nbf,
                    :ttl,
                    :valid_until,
                    :region

      def initialize(
        account_sid,
        signing_key_sid,
        secret,
        grants = [],
        identity: nil,
        nbf: nil,
        ttl: 3600,
        valid_until: nil,
        region: nil
      )
        super(secret_key: secret,
              issuer: signing_key_sid,
              subject: account_sid,
              nbf: nbf,
              ttl: ttl,
              valid_until: valid_until)
        @account_sid = account_sid
        @signing_key_sid = signing_key_sid
        @secret = secret
        @identity = identity
        @nbf = nbf
        @grants = grants
        @ttl = ttl
        @valid_until = valid_until
        @region = region
      end

      def add_grant(grant)
        @grants.push(grant)
      end

      protected

      def _generate_payload
        now = Time.now.to_i
        grants = {}
        grants[:identity] = @identity if @identity

        @grants.each { |grant| grants[grant._key] = grant._generate_payload } unless @grants.empty?

        payload = {
          jti: "#{@signing_key_sid}-#{now}",
          grants: grants
        }

        payload
      end

      protected

      def _generate_headers
        headers = {
          cty: 'twilio-fpa;v=1'
        }

        headers[:twr] = region unless region&.nil?

        headers
      end

      class ChatGrant
        include AccessTokenGrant
        attr_accessor :service_sid,
                      :endpoint_id,
                      :deployment_role_sid,
                      :push_credential_sid

        def _key
          'chat'
        end

        def _generate_payload
          payload = {}

          payload[:service_sid] = service_sid if service_sid

          payload[:endpoint_id] = endpoint_id if endpoint_id

          if deployment_role_sid
            payload[:deployment_role_sid] = deployment_role_sid
          end

          if push_credential_sid
            payload[:push_credential_sid] = push_credential_sid
          end

          payload
        end
      end

      class VoiceGrant
        include AccessTokenGrant
        attr_accessor :incoming_allow,
                      :outgoing_application_sid,
                      :outgoing_application_params,
                      :push_credential_sid,
                      :endpoint_id

        def _key
          'voice'
        end

        def _generate_payload
          payload = {}
          payload[:incoming] = { allow: true } if incoming_allow == true

          if outgoing_application_sid
            outgoing = {}
            outgoing[:application_sid] = outgoing_application_sid
            if outgoing_application_params
              outgoing[:params] = outgoing_application_params
            end

            payload[:outgoing] = outgoing
          end

          if push_credential_sid
            payload[:push_credential_sid] = push_credential_sid
          end

          payload[:endpoint_id] = endpoint_id if endpoint_id

          payload
        end
      end

      class SyncGrant
        include AccessTokenGrant
        attr_accessor :service_sid,
                      :endpoint_id

        def _key
          'data_sync'
        end

        def _generate_payload
          payload = {}

          payload['service_sid'] = service_sid if service_sid
          payload['endpoint_id'] = endpoint_id if endpoint_id

          payload
        end
      end

      class VideoGrant
        include AccessTokenGrant
        attr_accessor :room

        def _key
          'video'
        end

        def _generate_payload
          payload = {}

          payload[:room] = room if room

          payload
        end
      end

      class TaskRouterGrant
        include AccessTokenGrant
        attr_accessor :workspace_sid,
                      :worker_sid,
                      :role

        def _key
          'task_router'
        end

        def _generate_payload
          payload = {}

          payload[:workspace_sid] = workspace_sid if workspace_sid

          payload[:worker_sid] = worker_sid if worker_sid

          payload[:role] = role if role

          payload
        end
      end

      class PlaybackGrant
        include AccessTokenGrant
        attr_accessor :grant

        def _key
          'player'
        end

        def _generate_payload
          grant
        end
      end
    end
  end
end
