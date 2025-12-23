# frozen_string_literal: true

require 'jwt'
require 'oauth2'
require 'omniauth/strategies/oauth2'
require 'uri'

module OmniAuth
  module Strategies
    # Main class for Google OAuth2 strategy.
    class GoogleOauth2 < OmniAuth::Strategies::OAuth2
      ALLOWED_ISSUERS = ['accounts.google.com', 'https://accounts.google.com'].freeze
      BASE_SCOPE_URL = 'https://www.googleapis.com/auth/'
      BASE_SCOPES = %w[profile email openid].freeze
      DEFAULT_SCOPE = 'email,profile'
      USER_INFO_URL = 'https://www.googleapis.com/oauth2/v3/userinfo'
      IMAGE_SIZE_REGEXP = /(s\d+(-c)?)|(w\d+-h\d+(-c)?)|(w\d+(-c)?)|(h\d+(-c)?)|c/
      AUTHORIZE_OPTIONS = %i[access_type hd login_hint prompt request_visible_actions scope state redirect_uri include_granted_scopes enable_granular_consent openid_realm device_id device_name]

      option :name, 'google_oauth2'
      option :skip_friends, true
      option :skip_image_info, true
      option :skip_jwt, false
      option :jwt_leeway, 60
      option :authorize_options, AUTHORIZE_OPTIONS
      option :overridable_authorize_options, AUTHORIZE_OPTIONS
      option :authorized_client_ids, []

      option :client_options,
             site: 'https://oauth2.googleapis.com',
             authorize_url: 'https://accounts.google.com/o/oauth2/auth',
             token_url: '/token'

      def authorize_params
        super.tap do |params|
          (options[:authorize_options] & options[:overridable_authorize_options]).each do |k|
            params[k] = request.params[k.to_s] unless [nil, ''].include?(request.params[k.to_s])
          end

          params[:scope] = get_scope(params)
          params[:access_type] = 'offline' if params[:access_type].nil?
          params['openid.realm'] = params.delete(:openid_realm) unless params[:openid_realm].nil?

          session['omniauth.state'] = params[:state] if params[:state]
        end
      end

      uid { raw_info['sub'] }

      info do
        prune!(
          name: raw_info['name'],
          email: verified_email,
          unverified_email: raw_info['email'],
          email_verified: raw_info['email_verified'],
          first_name: raw_info['given_name'],
          last_name: raw_info['family_name'],
          image: image_url,
          urls: {
            google: raw_info['profile']
          }
        )
      end

      credentials do
        # Tokens and expiration will be used from OAuth2 strategy credentials block
        prune!({ 'scope' => token_info(access_token.token)['scope'] })
      end

      extra do
        hash = {}
        token = nil_or_empty?(access_token['id_token']) ? access_token.token : access_token['id_token']
        hash[:id_token] = token
        if !options[:skip_jwt] && !nil_or_empty?(token)
          decoded = ::JWT.decode(token, nil, false).first

          # We have to manually verify the claims because the third parameter to
          # JWT.decode is false since no verification key is provided.
          ::JWT::Verify.verify_claims(decoded,
                                      verify_iss: true,
                                      iss: ALLOWED_ISSUERS,
                                      verify_aud: true,
                                      aud: options.client_id,
                                      verify_sub: false,
                                      verify_expiration: true,
                                      verify_not_before: true,
                                      verify_iat: false,
                                      verify_jti: false,
                                      leeway: options[:jwt_leeway])

          hash[:id_info] = decoded
        end
        hash[:raw_info] = raw_info unless skip_info?
        prune! hash
      end

      def raw_info
        @raw_info ||= access_token.get(USER_INFO_URL).parsed
      end

      def custom_build_access_token
        access_token = get_access_token(request)

        verify_hd(access_token)
        access_token
      end

      alias build_access_token custom_build_access_token

      private

      def nil_or_empty?(obj)
        obj.is_a?(String) ? obj.empty? : obj.nil?
      end

      def callback_url
        options[:redirect_uri] || (full_host + callback_path)
      end

      def get_access_token(request)
        verifier = request.params['code']
        redirect_uri = request.params['redirect_uri']
        access_token = request.params['access_token']
        if verifier && request.xhr?
          client_get_token(verifier, redirect_uri || 'postmessage')
        elsif verifier
          client_get_token(verifier, redirect_uri || callback_url)
        elsif access_token && verify_token(access_token)
          ::OAuth2::AccessToken.from_hash(client, request.params.dup)
        elsif request.content_type =~ /json/i
          begin
            body = JSON.parse(request.body.read)
            request.body.rewind # rewind request body for downstream middlewares
            verifier = body && body['code']
            access_token = body && body['access_token']
            redirect_uri ||= body && body['redirect_uri']
            if verifier
              client_get_token(verifier, redirect_uri || 'postmessage')
            elsif verify_token(access_token)
              ::OAuth2::AccessToken.from_hash(client, body.dup)
            end
          rescue JSON::ParserError => e
            warn "[omniauth google-oauth2] JSON parse error=#{e}"
          end
        end
      end

      def client_get_token(verifier, redirect_uri)
        client.auth_code.get_token(verifier, get_token_options(redirect_uri), get_token_params)
      end

      def get_token_params
        deep_symbolize(options.auth_token_params || {})
      end

      def get_scope(params)
        raw_scope = params[:scope] || DEFAULT_SCOPE
        scope_list = raw_scope.split(' ').map { |item| item.split(',') }.flatten
        scope_list.map! { |s| s =~ %r{^https?://} || BASE_SCOPES.include?(s) ? s : "#{BASE_SCOPE_URL}#{s}" }
        scope_list.join(' ')
      end

      def verified_email
        raw_info['email_verified'] ? raw_info['email'] : nil
      end

      def get_token_options(redirect_uri = '')
        { redirect_uri: redirect_uri }.merge(token_params.to_hash(symbolize_keys: true))
      end

      def prune!(hash)
        hash.delete_if do |_, v|
          prune!(v) if v.is_a?(Hash)
          v.nil? || (v.respond_to?(:empty?) && v.empty?)
        end
      end

      def image_url
        return nil unless raw_info['picture']

        u = URI.parse(raw_info['picture'].gsub('https:https', 'https'))

        path_index = u.path.to_s.index('/photo.jpg')

        if path_index && image_size_opts_passed?
          u.path.insert(path_index, image_params)
          u.path = u.path.gsub('//', '/')

          # Check if the image is already sized!
          split_path = u.path.split('/')
          u.path = u.path.sub("/#{split_path[-3]}", '') if split_path[-3] =~ IMAGE_SIZE_REGEXP
        end

        u.query = strip_unnecessary_query_parameters(u.query)

        u.to_s
      end

      def image_size_opts_passed?
        options[:image_size] || options[:image_aspect_ratio]
      end

      def image_params
        image_params = []
        if options[:image_size].is_a?(Integer)
          image_params << "s#{options[:image_size]}"
        elsif options[:image_size].is_a?(Hash)
          image_params << "w#{options[:image_size][:width]}" if options[:image_size][:width]
          image_params << "h#{options[:image_size][:height]}" if options[:image_size][:height]
        end
        image_params << 'c' if options[:image_aspect_ratio] == 'square'

        '/' + image_params.join('-')
      end

      def strip_unnecessary_query_parameters(query_parameters)
        # strip `sz` parameter (defaults to sz=50) which overrides `image_size` options
        return nil if query_parameters.nil?

        params = CGI.parse(query_parameters)
        stripped_params = params.delete_if { |key| key == 'sz' }

        # don't return an empty Hash since that would result
        # in URLs with a trailing ? character: http://image.url?
        return nil if stripped_params.empty?

        URI.encode_www_form(stripped_params)
      end

      def token_info(access_token)
        return nil unless access_token

        @token_info ||= Hash.new do |h, k|
          h[k] = client.request(:post, 'https://www.googleapis.com/oauth2/v3/tokeninfo', body: { access_token: access_token }).parsed
        end

        @token_info[access_token]
      end

      def verify_token(access_token)
        return false unless access_token

        token_info = token_info(access_token)
        token_info['aud'] == options.client_id || options.authorized_client_ids.include?(token_info['aud'])
      end

      def verify_hd(access_token)
        return true unless options.hd

        @raw_info ||= access_token.get(USER_INFO_URL).parsed

        options.hd = options.hd.call if options.hd.is_a? Proc
        allowed_hosted_domains = Array(options.hd)

        raise CallbackError.new(:invalid_hd, 'Invalid Hosted Domain') unless allowed_hosted_domains.include?(@raw_info['hd']) || options.hd == '*'

        true
      end
    end
  end
end
