# frozen_string_literal: true

# this gem is an extension of oauth gem
require "oauth/helper"
require "oauth/request_proxy"

module OAuth
  module TTY
    module Commands
      class SignCommand < Command
        def required_options
          %i[oauth_consumer_key oauth_consumer_secret oauth_token oauth_token_secret]
        end

        def _run
          request = OAuth::RequestProxy.proxy \
            "method" => options[:method],
            "uri" => options[:uri],
            "parameters" => parameters

          puts_verbose_parameters(request) if verbose?

          request.sign! \
            consumer_secret: options[:oauth_consumer_secret],
            token_secret: options[:oauth_token_secret]

          if verbose?
            puts_verbose_request(request)
          else
            puts request.oauth_signature
          end
        end

        def puts_verbose_parameters(request)
          puts "OAuth parameters:"
          request.oauth_parameters.each do |k, v|
            puts "  #{[k, v].join(": ")}"
          end
          puts

          if request.non_oauth_parameters.any?
            puts "Parameters:"
            request.non_oauth_parameters.each do |k, v|
              puts "  #{[k, v].join(": ")}"
            end
            puts
          end
        end

        def puts_verbose_request(request)
          puts "Method: #{request.method}"
          puts "URI: #{request.uri}"
          puts "Normalized params: #{request.normalized_parameters}" unless options[:xmpp]
          puts "Signature base string: #{request.signature_base_string}"

          if xmpp?
            puts
            puts "XMPP Stanza:"
            puts xmpp_output(request)
            puts
            puts "Note: You may want to use bare JIDs in your URI."
            puts
          else
            puts "OAuth Request URI: #{request.signed_uri}"
            puts "Request URI: #{request.signed_uri(with_oauth: false)}"
            puts "Authorization header: #{request.oauth_header(realm: options[:realm])}"
          end
          puts "Signature:         #{request.oauth_signature}"
          puts "Escaped signature: #{OAuth::Helper.escape(request.oauth_signature)}"
        end

        def xmpp_output(request)
          <<-EOS
    <oauth xmlns='urn:xmpp:oauth:0'>
      <oauth_consumer_key>#{request.oauth_consumer_key}</oauth_consumer_key>
      <oauth_token>#{request.oauth_token}</oauth_token>
      <oauth_signature_method>#{request.oauth_signature_method}</oauth_signature_method>
      <oauth_signature>#{request.oauth_signature}</oauth_signature>
      <oauth_timestamp>#{request.oauth_timestamp}</oauth_timestamp>
      <oauth_nonce>#{request.oauth_nonce}</oauth_nonce>
      <oauth_version>#{request.oauth_version}</oauth_version>
    </oauth>
          EOS
        end
      end
    end
  end
end
