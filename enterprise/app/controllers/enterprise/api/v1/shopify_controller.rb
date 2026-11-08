class Enterprise::Api::V1::ShopifyController < Enterprise::Api::V1::AccountsController
  before_action :ensure_shopify_billing_available

  def reconnect_shopify
    return render_not_found_error('Not found') unless shopify_billing? && @account.signup_source == 'shopify'

    pending_installation = Shopify::PendingInstallation.claim(token: params[:pending_install_token])
    Shopify::InstallationService.new(account: @account, pending_installation: pending_installation).perform
    head :ok
  rescue Shopify::PendingInstallation::AlreadyClaimed => e
    pending_installation&.release!
    render json: { error: e.message }, status: :conflict
  rescue Shopify::PendingInstallation::CommitOutcomeUnknown
    raise
  rescue Shopify::PendingInstallation::Error => e
    pending_installation&.release!
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError
    pending_installation&.release!
    raise
  end

  private

  def check_authorization
    authorize(Account, :reconnect_shopify?)
  end
end
