# frozen_string_literal: true

require 'rack/protection'
require 'securerandom'
require 'openssl'
require 'base64'

module Rack
  module Protection
    ##
    # Prevented attack::   CSRF
    # Supported browsers:: all
    # More infos::         http://en.wikipedia.org/wiki/Cross-site_request_forgery
    #
    # This middleware only accepts requests other than <tt>GET</tt>,
    # <tt>HEAD</tt>, <tt>OPTIONS</tt>, <tt>TRACE</tt> if their given access
    # token matches the token included in the session.
    #
    # It checks the <tt>X-CSRF-Token</tt> header and the <tt>POST</tt> form
    # data.
    #
    # It is not OOTB-compatible with the {rack-csrf}[https://rubygems.org/gems/rack_csrf] gem.
    # For that, the following patch needs to be applied:
    #
    #   Rack::Protection::AuthenticityToken.default_options(key: "csrf.token", authenticity_param: "_csrf")
    #
    # == Options
    #
    # [<tt>:authenticity_param</tt>] the name of the param that should contain
    #                                the token on a request. Default value:
    #                                <tt>"authenticity_token"</tt>
    #
    # [<tt>:key</tt>] the name of the param that should contain
    #                                the token in the session. Default value:
    #                                <tt>:csrf</tt>
    #
    # [<tt>:allow_if</tt>] a proc for custom allow/deny logic. Default value:
    #                                <tt>nil</tt>
    #
    # == Example: Forms application
    #
    # To show what the AuthenticityToken does, this section includes a sample
    # program which shows two forms. One with, and one without a CSRF token
    # The one without CSRF token field will get a 403 Forbidden response.
    #
    # Install the gem, then run the program:
    #
    #   gem install 'rack-protection'
    #   puma server.ru
    #
    # Here is <tt>server.ru</tt>:
    #
    #   require 'rack/protection'
    #   require 'rack/session'
    #
    #   app = Rack::Builder.app do
    #     use Rack::Session::Cookie, secret: 'CHANGEMEaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    #     use Rack::Protection::AuthenticityToken
    #
    #     run -> (env) do
    #       [200, {}, [
    #         <<~EOS
    #           <!DOCTYPE html>
    #           <html lang="en">
    #           <head>
    #             <meta charset="UTF-8" />
    #             <title>rack-protection minimal example</title>
    #           </head>
    #           <body>
    #             <h1>Without Authenticity Token</h1>
    #             <p>This takes you to <tt>Forbidden</tt></p>
    #             <form action="" method="post">
    #               <input type="text" name="foo" />
    #               <input type="submit" />
    #             </form>
    #
    #             <h1>With Authenticity Token</h1>
    #             <p>This successfully takes you to back to this form.</p>
    #             <form action="" method="post">
    #               <input type="hidden" name="authenticity_token" value="#{Rack::Protection::AuthenticityToken.token(env['rack.session'])}" />
    #               <input type="text" name="foo" />
    #               <input type="submit" />
    #             </form>
    #           </body>
    #           </html>
    #         EOS
    #       ]]
    #     end
    #   end
    #
    #   run app
    #
    # == Example: Customize which POST parameter holds the token
    #
    # To customize the authenticity parameter for form data, use the
    # <tt>:authenticity_param</tt> option:
    #   use Rack::Protection::AuthenticityToken, authenticity_param: 'your_token_param_name'
    class AuthenticityToken < Base
      TOKEN_LENGTH = 32

      default_options authenticity_param: 'authenticity_token',
                      key: :csrf,
                      allow_if: nil

      def self.token(session, path: nil, method: :post)
        new(nil).mask_authenticity_token(session, path: path, method: method)
      end

      def self.random_token
        SecureRandom.urlsafe_base64(TOKEN_LENGTH, padding: false)
      end

      def accepts?(env)
        session = session(env)
        set_token(session)

        safe?(env) ||
          valid_token?(env, env['HTTP_X_CSRF_TOKEN']) ||
          valid_token?(env, Request.new(env).params[options[:authenticity_param]]) ||
          options[:allow_if]&.call(env)
      rescue StandardError
        false
      end

      def mask_authenticity_token(session, path: nil, method: :post)
        set_token(session)

        token = if path && method
                  per_form_token(session, path, method)
                else
                  global_token(session)
                end

        mask_token(token)
      end

      GLOBAL_TOKEN_IDENTIFIER = '!real_csrf_token'
      private_constant :GLOBAL_TOKEN_IDENTIFIER

      private

      def set_token(session)
        session[options[:key]] ||= self.class.random_token
      end

      # Checks the client's masked token to see if it matches the
      # session token.
      def valid_token?(env, token)
        return false if token.nil? || !token.is_a?(String) || token.empty?

        session = session(env)

        begin
          token = decode_token(token)
        rescue ArgumentError # encoded_masked_token is invalid Base64
          return false
        end

        # See if it's actually a masked token or not. We should be able
        # to handle any unmasked tokens that we've issued without error.

        if unmasked_token?(token)
          compare_with_real_token(token, session)
        elsif masked_token?(token)
          token = unmask_token(token)

          compare_with_global_token(token, session) ||
            compare_with_real_token(token, session) ||
            compare_with_per_form_token(token, session, Request.new(env))
        else
          false # Token is malformed
        end
      end

      # Creates a masked version of the authenticity token that varies
      # on each request. The masking is used to mitigate SSL attacks
      # like BREACH.
      def mask_token(token)
        one_time_pad = SecureRandom.random_bytes(token.length)
        encrypted_token = xor_byte_strings(one_time_pad, token)
        masked_token = one_time_pad + encrypted_token
        encode_token(masked_token)
      end

      # Essentially the inverse of +mask_token+.
      def unmask_token(masked_token)
        # Split the token into the one-time pad and the encrypted
        # value and decrypt it
        token_length = masked_token.length / 2
        one_time_pad = masked_token[0...token_length]
        encrypted_token = masked_token[token_length..]
        xor_byte_strings(one_time_pad, encrypted_token)
      end

      def unmasked_token?(token)
        token.length == TOKEN_LENGTH
      end

      def masked_token?(token)
        token.length == TOKEN_LENGTH * 2
      end

      def compare_with_real_token(token, session)
        secure_compare(token, real_token(session))
      end

      def compare_with_global_token(token, session)
        secure_compare(token, global_token(session))
      end

      def compare_with_per_form_token(token, session, request)
        secure_compare(token,
                       per_form_token(session, request.path.chomp('/'), request.request_method))
      end

      def real_token(session)
        decode_token(session[options[:key]])
      end

      def global_token(session)
        token_hmac(session, GLOBAL_TOKEN_IDENTIFIER)
      end

      def per_form_token(session, path, method)
        token_hmac(session, "#{path}##{method.downcase}")
      end

      def encode_token(token)
        Base64.urlsafe_encode64(token)
      end

      def decode_token(token)
        Base64.urlsafe_decode64(token)
      end

      def token_hmac(session, identifier)
        OpenSSL::HMAC.digest(
          OpenSSL::Digest.new('SHA256'),
          real_token(session),
          identifier
        )
      end

      def xor_byte_strings(s1, s2)
        s2 = s2.dup
        size = s1.bytesize
        i = 0
        while i < size
          s2.setbyte(i, s1.getbyte(i) ^ s2.getbyte(i))
          i += 1
        end
        s2
      end
    end
  end
end
