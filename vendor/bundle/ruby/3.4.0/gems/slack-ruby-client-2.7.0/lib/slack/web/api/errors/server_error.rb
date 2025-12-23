# frozen_string_literal: true
module Slack
  module Web
    module Api
      module Errors
        class ServerError < ::Faraday::Error
          attr_reader :response

          def initialize(message, response)
            @response = response
            super message
          end
        end

        class ParsingError < ServerError
          def initialize(response)
            super('parsing_error', response)
          end
        end

        class HttpRequestError < ServerError; end

        class TimeoutError < HttpRequestError
          def initialize(response)
            super('timeout_error', response)
          end
        end

        class UnavailableError < HttpRequestError
          def initialize(response)
            super('unavailable_error', response)
          end
        end
      end
    end
  end
end
