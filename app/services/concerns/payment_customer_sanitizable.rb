module PaymentCustomerSanitizable
  extend ActiveSupport::Concern

  private

  DEFAULT_CUSTOMER_NAME = 'Customer'.freeze

  def sanitize_customer_name(name)
    return DEFAULT_CUSTOMER_NAME if name.blank?

    sanitized = name.gsub(/[^\p{L}\s'\-.]/, '').gsub(/\s+/, ' ').strip
    sanitized.length >= 2 && sanitized.match?(/\p{L}/) ? sanitized : DEFAULT_CUSTOMER_NAME
  end
end
