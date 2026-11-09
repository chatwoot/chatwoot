module Enterprise::Api::V1::Accounts::Integrations::BaseController
  private

  def check_authorization
    super
    return unless shopify_billing_hook_mutation?

    render json: { error: 'Shopify-billed integrations must be managed in Shopify' }, status: :unprocessable_entity
  end

  def shopify_billing_hook_mutation?
    %w[update destroy].include?(action_name) &&
      @hook&.app_id == 'shopify' &&
      Current.account.billing_provider == 'shopify' &&
      Current.account.signup_source == 'shopify'
  end
end
