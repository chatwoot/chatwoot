# frozen_string_literal: true

require "xmpp4r"
require "oauth/request_proxy/base"

module OAuth
  module RequestProxy
    class JabberRequest < OAuth::RequestProxy::Base
      proxies ::Jabber::Iq
      proxies ::Jabber::Presence
      proxies ::Jabber::Message

      def parameters
        return @params if @params

        @params = {}

        oauth = @request.get_elements("//oauth").first
        return @params unless oauth

        %w[ oauth_token oauth_consumer_key oauth_signature_method oauth_signature
            oauth_timestamp oauth_nonce oauth_version ].each do |param|
          next unless (element = oauth.first_element(param))

          @params[param] = element.text
        end

        @params
      end

      def method
        @request.name
      end

      def uri
        [@request.from.strip.to_s, @request.to.strip.to_s].join("&")
      end

      def normalized_uri
        uri
      end
    end
  end
end
