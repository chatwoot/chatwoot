# frozen_string_literal: true

module Sentry
  class Error < StandardError
  end

  class ExternalError < Error
  end
end
