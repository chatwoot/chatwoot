# frozen_string_literal: true

require "oauth/request_proxy"
require "oauth/helper"

module OAuth
  module RequestProxy
    class Base
      include OAuth::Helper

      def self.proxies(klass)
        OAuth::RequestProxy.available_proxies[klass] = self
      end

      attr_accessor :request, :options, :unsigned_parameters

      def initialize(request, options = {})
        @request = request
        @unsigned_parameters = (options[:unsigned_parameters] || []).map(&:to_s)
        @options = options
      end

      ## OAuth parameters

      def oauth_callback
        parameters["oauth_callback"]
      end

      def oauth_consumer_key
        parameters["oauth_consumer_key"]
      end

      def oauth_nonce
        parameters["oauth_nonce"]
      end

      def oauth_signature
        # TODO: can this be nil?
        [parameters["oauth_signature"]].flatten.first || ""
      end

      def oauth_signature_method
        case parameters["oauth_signature_method"]
        when Array
          parameters["oauth_signature_method"].first
        else
          parameters["oauth_signature_method"]
        end
      end

      def oauth_timestamp
        parameters["oauth_timestamp"]
      end

      def oauth_token
        parameters["oauth_token"]
      end

      def oauth_verifier
        parameters["oauth_verifier"]
      end

      def oauth_version
        parameters["oauth_version"]
      end

      # TODO: deprecate these
      alias consumer_key oauth_consumer_key
      alias token oauth_token
      alias nonce oauth_nonce
      alias timestamp oauth_timestamp
      alias signature oauth_signature
      alias signature_method oauth_signature_method

      ## Parameter accessors

      def parameters
        raise NotImplementedError, "Must be implemented by subclasses"
      end

      def parameters_for_signature
        parameters.select { |k, _v| !signature_and_unsigned_parameters.include?(k) }
      end

      def oauth_parameters
        parameters.select { |k, v| OAuth::PARAMETERS.include?(k) && !v.nil? && v != "" }
      end

      def non_oauth_parameters
        parameters.select { |k, _v| !OAuth::PARAMETERS.include?(k) }
      end

      def signature_and_unsigned_parameters
        unsigned_parameters + ["oauth_signature"]
      end

      # See 9.1.2 in specs
      def normalized_uri
        u = URI.parse(uri)
        "#{u.scheme.downcase}://#{u.host.downcase}#{(u.scheme.casecmp("http").zero? && u.port != 80) || (u.scheme.casecmp("https").zero? && u.port != 443) ? ":#{u.port}" : ""}#{u.path && u.path != "" ? u.path : "/"}"
      end

      # See 9.1.1. in specs Normalize Request Parameters
      def normalized_parameters
        normalize(parameters_for_signature)
      end

      def sign(options = {})
        OAuth::Signature.sign(self, options)
      end

      def sign!(options = {})
        parameters["oauth_signature"] = sign(options)
        @signed = true
        signature
      end

      # See 9.1 in specs
      def signature_base_string
        base = [method, normalized_uri, normalized_parameters]
        base.map { |v| escape(v) }.join("&")
      end

      # Has this request been signed yet?
      def signed?
        @signed
      end

      # URI, including OAuth parameters
      def signed_uri(with_oauth: true)
        if signed?
          params = if with_oauth
                     parameters
                   else
                     non_oauth_parameters
                   end

          [uri, normalize(params)].join("?")
        else
          warn "This request has not yet been signed!"
        end
      end

      # Authorization header for OAuth
      def oauth_header(options = {})
        header_params_str = oauth_parameters.map { |k, v| "#{k}=\"#{escape(v)}\"" }.join(", ")

        realm = "realm=\"#{options[:realm]}\", " if options[:realm]
        "OAuth #{realm}#{header_params_str}"
      end

      def query_string_blank?
        if (uri = request.env["REQUEST_URI"])
          uri.split("?", 2)[1].nil?
        else
          request.query_string.match(/\A\s*\z/)
        end
      end

      protected

      def header_params
        %w[X-HTTP_AUTHORIZATION Authorization HTTP_AUTHORIZATION].each do |header|
          next unless request.env.include?(header)

          header = request.env[header]
          next unless header[0, 6] == "OAuth "

          # parse the header into a Hash
          oauth_params = OAuth::Helper.parse_header(header)

          # remove non-OAuth parameters
          oauth_params.select! { |k, _v| k =~ /^oauth_/ }

          return oauth_params
        end

        {}
      end
    end
  end
end
