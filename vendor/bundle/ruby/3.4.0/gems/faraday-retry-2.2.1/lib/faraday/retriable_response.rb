# frozen_string_literal: true

# Faraday namespace.
module Faraday
  # Exception used to control the Retry middleware.
  class RetriableResponse < Error
  end
end
