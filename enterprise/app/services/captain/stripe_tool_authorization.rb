# Local MVP policy for the read-only Stripe catalog tools. Identity comes from the
# persisted conversation, never from an email or customer ID chosen by the model.
class Captain::StripeToolAuthorization
  Unauthorized = Captain::ToolCustomerAuthorization::Unauthorized

  PATHS = %w[/v1/customers/search /v1/payment_intents /v1/invoices /v1/subscriptions].freeze

  def initialize(tool:, email:)
    @tool = tool
    @email = email
  end

  def parameters
    path, token = stripe_configuration!
    return { email: @email } if path == '/v1/customers/search'

    customers = Stripe::Customer.list({ email: @email, limit: 2 }, { api_key: token })
    unless customers.data.one? && !customers.has_more
      raise Unauthorized, 'A unique Stripe customer could not be identified. Hand off to a human agent.'
    end

    { customer_id: customers.data.first.id }
  end

  private

  def stripe_configuration!
    path = @tool.endpoint_url.split('?').first.delete_prefix('https://api.stripe.com')
    unless @tool.http_method == 'GET' && PATHS.include?(path) && @tool.auth_type == 'bearer'
      raise Unauthorized, 'Only the read-only Stripe catalog tools are supported by this MVP.'
    end

    token = @tool.auth_config['token'].to_s
    raise Unauthorized, 'Configure a Stripe test key before using this tool.' unless token.start_with?('rk_test_', 'sk_test_')

    [path, token]
  end
end
