module Integrations::Woocommerce
  class Error < StandardError; end
  class ApiError < Error; end
  class AuthenticationError < Error; end
  class NotFoundError < Error; end
end
