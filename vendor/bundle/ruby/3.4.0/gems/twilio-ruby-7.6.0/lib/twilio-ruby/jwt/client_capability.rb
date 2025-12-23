# frozen_string_literal: true

module Twilio
  module JWT
    module Scope
      def _generate_payload
        raise 'Not Implemented'
      end
    end

    class ClientCapability < BaseJWT
      attr_accessor :account_sid,
                    :auth_token,
                    :client_name,
                    :scopes

      def initialize(account_sid, auth_token, scopes: [], nbf: nil, ttl: 3600, valid_until: nil)
        super(secret_key: auth_token, issuer: account_sid, nbf: nbf, ttl: ttl, valid_until: valid_until)
        @account_sid = account_sid
        @auth_token = auth_token
        @client_name = nil
        @scopes = scopes
      end

      def add_scope(scope)
        @scopes.push(scope)
      end

      protected

      def _generate_payload
        scope = ''
        scope = @scopes.map(&:_generate_payload).join(' ') unless @scopes.empty?

        payload = {
          scope: scope
        }

        payload
      end

      class IncomingClientScope
        include Scope

        def initialize(client_name)
          @client_name = client_name
        end

        def _generate_payload
          prefix = 'scope:client:incoming'
          suffix = 'clientName=' + CGI.escape(@client_name.to_s)

          [prefix, suffix].join('?')
        end
      end

      class OutgoingClientScope
        include Scope

        def initialize(application_sid, client_name = nil, params = {})
          @application_sid = application_sid
          @client_name = client_name
          @params = params
        end

        def _generate_payload
          prefix = 'scope:client:outgoing'
          application_sid = "appSid=#{CGI.escape(@application_sid)}"
          unless @client_name.nil?
            client_name = "clientName=#{CGI.escape(@client_name)}"
          end
          unless @params.empty?
            params = 'appParams=' + @params.map { |k, v| CGI.escape("#{k}=#{v}") }.join(CGI.escape('&'))
          end

          suffix = [application_sid, client_name, params].compact.join('&')
          [prefix, suffix].join('?')
        end
      end

      class EventStreamScope
        include Scope

        def initialize(filters = {})
          @filters = filters
          @path = '/2010-04-01/Events'
        end

        def _generate_payload
          prefix = 'scope:stream:subscribe'
          path = "path=#{CGI.escape(@path)}"
          unless @filters.empty?
            filters = 'params=' + @filters.map { |k, v| CGI.escape("#{k}=#{v}") }.join('&')
          end

          suffix = [path, filters].compact.join('&')
          [prefix, suffix].join('?')
        end
      end
    end
  end
end
