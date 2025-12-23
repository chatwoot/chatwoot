# frozen_string_literal: true

require "active_support"
require "action_controller"
require "uri"

require "action_dispatch/http/request"

module OAuth
  module RequestProxy
    class ActionControllerRequest < OAuth::RequestProxy::Base
      proxies(::ActionDispatch::Request)

      def method
        request.method.to_s.upcase
      end

      def uri
        request.url
      end

      def parameters
        if options[:clobber_request]
          options[:parameters] || {}
        else
          params = request_params.merge(query_params).merge(header_params)
          params.stringify_keys! if params.respond_to?(:stringify_keys!)
          params.merge(options[:parameters] || {})
        end
      end

      # Override from OAuth::RequestProxy::Base to avoid round-trip
      # conversion to Hash or Array and thus preserve the original
      # parameter names
      def parameters_for_signature
        params = []
        params << options[:parameters].to_query if options[:parameters]

        unless options[:clobber_request]
          params << header_params.to_query
          params << request.query_string unless query_string_blank?

          params << request.raw_post if raw_post_signature?
        end

        params.
          join("&").split("&").
          reject { |s| s.match(/\A\s*\z/) }.
          map { |p| p.split("=").map { |esc| CGI.unescape(esc) } }.
          reject { |kv| kv[0] == "oauth_signature" }
      end

      def raw_post_signature?
        (request.post? || request.put?) && request.content_type.to_s.downcase.start_with?("application/x-www-form-urlencoded")
      end

      protected

      def query_params
        request.query_parameters
      end

      def request_params
        request.request_parameters
      end
    end
  end
end
