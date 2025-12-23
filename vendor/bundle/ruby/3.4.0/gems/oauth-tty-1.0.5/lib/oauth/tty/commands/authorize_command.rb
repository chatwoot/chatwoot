# frozen_string_literal: true

# this gem is an extension of oauth gem
require "oauth/consumer"
require "oauth/errors/unauthorized"

module OAuth
  module TTY
    module Commands
      class AuthorizeCommand < Command
        def required_options
          [:uri]
        end

        def _run
          request_token = get_request_token

          if request_token.callback_confirmed?
            puts "Server appears to support OAuth 1.0a; enabling support."
            options[:version] = "1.0a"
          end

          puts "Please visit this url to authorize:"
          puts request_token.authorize_url

          # parameters for OAuth 1.0a
          oauth_verifier = ask_user_for_verifier

          verbosely_get_access_token(request_token, oauth_verifier)
        end

        def get_request_token
          consumer = get_consumer
          scope_options = options[:scope] ? { "scope" => options[:scope] } : {}
          consumer.get_request_token({ oauth_callback: options[:oauth_callback] }, scope_options)
        rescue OAuth::Unauthorized => e
          alert "A problem occurred while attempting to authorize:"
          alert e
          alert e.request.body
        end

        def get_consumer
          OAuth::Consumer.new \
            options[:oauth_consumer_key],
            options[:oauth_consumer_secret],
            access_token_url: options[:access_token_url],
            authorize_url: options[:authorize_url],
            request_token_url: options[:request_token_url],
            scheme: options[:scheme],
            http_method: options[:method].to_s.downcase.to_sym
        end

        def ask_user_for_verifier
          if options[:version] == "1.0a"
            puts "Please enter the verification code provided by the SP (oauth_verifier):"
            @stdin.gets.chomp
          else
            puts "Press return to continue..."
            @stdin.gets
            nil
          end
        end

        def verbosely_get_access_token(request_token, oauth_verifier)
          access_token = request_token.get_access_token(oauth_verifier: oauth_verifier)

          puts "Response:"
          access_token.params.each do |k, v|
            puts "  #{k}: #{v}" unless k.is_a?(Symbol)
          end
        rescue OAuth::Unauthorized => e
          alert "A problem occurred while attempting to obtain an access token:"
          alert e
          alert e.request.body
        end
      end
    end
  end
end
