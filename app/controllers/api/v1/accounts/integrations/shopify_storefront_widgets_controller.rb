class Api::V1::Accounts::Integrations::ShopifyStorefrontWidgetsController < Api::V1::Accounts::Integrations::BaseController
  before_action :authorize_widget
  before_action :load_public_app

  rescue_from Shopify::StorefrontWidget::ProviderError do |error|
    Rails.logger.warn(error.message)
    head :bad_gateway
  end

  rescue_from Shopify::StorefrontWidget::ReauthorizationRequired do
    render json: { code: 'shopify_reauthorization_required' }, status: :conflict
  end

  def show
    token = widget.website_token
    inbox = Channel::WebWidget.find_by(account: Current.account, website_token: token)&.inbox if token.present?
    render json: { inbox_id: inbox&.id, theme_editor_url: inbox ? widget.theme_editor_url : nil }
  end

  def update
    inbox_id = params[:inbox_id]
    return head :unprocessable_entity unless inbox_id.is_a?(Integer) && inbox_id.positive?

    inbox = website_inboxes.find_by(id: inbox_id)
    return head :unprocessable_entity unless inbox

    theme_editor_url = @hook.with_lock do
      next unless @hook.enabled? && public_app_hook?

      editor_url = widget.theme_editor_url
      widget.save!(website_token: inbox.channel.website_token)
      editor_url
    end
    return head :not_found unless theme_editor_url

    render json: { inbox_id: inbox.id, theme_editor_url: theme_editor_url }
  end

  private

  def authorize_widget
    authorize(:hook, :update?)
  end

  def load_public_app
    return head :not_found unless ChatwootApp.chatwoot_cloud? && Shopify::FeatureGate.enabled?(account: Current.account)

    @hook = Current.account.hooks.enabled.find_by!(app_id: 'shopify')
    head :not_found unless public_app_hook?
  end

  def public_app_hook?
    @hook.settings&.fetch('custom_app_id', nil).blank?
  end

  def website_inboxes
    Current.account.inboxes.where(channel_type: 'Channel::WebWidget')
  end

  def widget
    @widget ||= Shopify::StorefrontWidget.new(hook: @hook)
  end
end
