# frozen_string_literal: true
module Slack
  module Web
    module Faraday
      module Response
        class WrapError < ::Faraday::Middleware
          UNAVAILABLE_ERROR_STATUSES = (500..599).freeze

          def on_complete(env)
            return unless UNAVAILABLE_ERROR_STATUSES.cover?(env.status)

            raise Slack::Web::Api::Errors::UnavailableError, env.response
          end

          def call(env)
            super
          rescue ::Faraday::TimeoutError, ::Faraday::ConnectionFailed
            raise Slack::Web::Api::Errors::TimeoutError, env.response
          end
        end
      end
    end
  end
end
