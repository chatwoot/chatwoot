# frozen_string_literal: true

class CustomExceptions::RateLimitExceeded < CustomExceptions::Base
  def http_status
    429  # Too Many Requests
  end

  def message
    @data[:message] || 'Rate limit exceeded'
  end
end
