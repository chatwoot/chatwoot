# frozen_string_literal: true

require "oauth/client"
require "oauth/consumer"
require "oauth/helper"
require "oauth/token"
require "oauth/signature/hmac/sha1"

module OAuth
  module Client
    class Helper
      include OAuth::Helper

      def initialize(request, options = {})
        @request = request
        @options = options
        @options[:signature_method] ||= "HMAC-SHA1"
      end

      attr_reader :options

      def nonce
        options[:nonce] ||= generate_key
      end

      def timestamp
        options[:timestamp] ||= generate_timestamp
      end

      def oauth_parameters
        out = {
          "oauth_body_hash" => options[:body_hash],
          "oauth_callback" => options[:oauth_callback],
          "oauth_consumer_key" => options[:consumer].key,
          "oauth_token" => options[:token] ? options[:token].token : "",
          "oauth_signature_method" => options[:signature_method],
          "oauth_timestamp" => timestamp,
          "oauth_nonce" => nonce,
          "oauth_verifier" => options[:oauth_verifier],
          "oauth_version" => (options[:oauth_version] || "1.0"),
          "oauth_session_handle" => options[:oauth_session_handle]
        }
        allowed_empty_params = options[:allow_empty_params]
        if allowed_empty_params != true && !allowed_empty_params.is_a?(Array)
          allowed_empty_params = allowed_empty_params == false ? [] : [allowed_empty_params]
        end
        out.select! { |k, v| v.to_s != "" || allowed_empty_params == true || allowed_empty_params.include?(k) }
        out
      end

      def signature(extra_options = {})
        OAuth::Signature.sign(@request, { uri: options[:request_uri],
                                          consumer: options[:consumer],
                                          token: options[:token],
                                          unsigned_parameters: options[:unsigned_parameters] }.merge(extra_options))
      end

      def signature_base_string(extra_options = {})
        OAuth::Signature.signature_base_string(@request, { uri: options[:request_uri],
                                                           consumer: options[:consumer],
                                                           token: options[:token],
                                                           parameters: oauth_parameters }.merge(extra_options))
      end

      def token_request?
        @options[:token_request].eql?(true)
      end

      def hash_body
        @options[:body_hash] = OAuth::Signature.body_hash(@request, parameters: oauth_parameters)
      end

      def amend_user_agent_header(headers)
        @oauth_ua_string ||= "OAuth gem v#{OAuth::Version::VERSION}"
        # Net::HTTP in 1.9 appends Ruby
        if headers["User-Agent"] && headers["User-Agent"] != "Ruby"
          headers["User-Agent"] += " (#{@oauth_ua_string})"
        else
          headers["User-Agent"] = @oauth_ua_string
        end
      end

      def header
        parameters = oauth_parameters
        parameters["oauth_signature"] = signature(options.merge(parameters: parameters))

        header_params_str = parameters.sort.map { |k, v| "#{k}=\"#{escape(v)}\"" }.join(", ")

        realm = "realm=\"#{options[:realm]}\", " if options[:realm]
        "OAuth #{realm}#{header_params_str}"
      end

      def parameters
        OAuth::RequestProxy.proxy(@request).parameters
      end

      def parameters_with_oauth
        oauth_parameters.merge(parameters)
      end
    end
  end
end
