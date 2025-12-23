# frozen_string_literal: true

require "oauth/request_proxy/base"
# em-http also uses adddressable so there is no need to require uri.
require "em-http"
require "cgi"

module OAuth
  module RequestProxy
    module EventMachine
      class HttpRequest < OAuth::RequestProxy::Base
        # A Proxy for use when you need to sign EventMachine::HttpClient instances.
        # It needs to be called once the client is construct but before data is sent.
        # Also see oauth/client/em-http
        proxies ::EventMachine::HttpClient

        # Request in this con

        def method
          request.req[:method]
        end

        def uri
          request.conn.normalize.to_s
        end

        def parameters
          if options[:clobber_request]
            options[:parameters]
          else
            all_parameters
          end
        end

        protected

        def all_parameters
          merged_parameters({}, post_parameters, query_parameters, options[:parameters])
        end

        def query_parameters
          quer = request.req[:query]
          hash_quer = if quer.respond_to?(:merge)
                        quer
                      else
                        CGI.parse(quer.to_s)
                      end
          CGI.parse(request.conn.query.to_s).merge(hash_quer)
        end

        def post_parameters
          headers = request.req[:head] || {}
          form_encoded = headers["Content-Type"].to_s.downcase.start_with?("application/x-www-form-urlencoded")
          if %w[POST PUT].include?(method) && form_encoded
            CGI.parse(request.normalize_body(request.req[:body]).to_s)
          else
            {}
          end
        end

        def merged_parameters(params, *extra_params)
          extra_params.compact.each do |params_pairs|
            params_pairs.each_pair do |key, value|
              if params.key?(key)
                params[key.to_s] += value
              else
                params[key.to_s] = [value].flatten
              end
            end
          end
          params
        end
      end
    end
  end
end
