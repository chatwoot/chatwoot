# frozen_string_literal: true

module Sentry
  module Utils
    module RequestId
      REQUEST_ID_HEADERS = %w[action_dispatch.request_id HTTP_X_REQUEST_ID].freeze

      # Request ID based on ActionDispatch::RequestId
      def self.read_from(env)
        REQUEST_ID_HEADERS.each do |key|
          request_id = env[key]
          return request_id if request_id
        end
        nil
      end
    end
  end
end
