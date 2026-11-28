class Api::V1::Accounts::Integrations::BaseController < Api::V1::Accounts::BaseController
  private

  def destroy_integration_hook!
    return @hook.destroy! unless @hook.shopify?

    @hook.with_lock do
      Shopify::StorefrontWidget.new(hook: @hook).clear! if @hook.settings&.fetch('custom_app_id', nil).blank?
      @hook.destroy!
    end
  end

  # Managing an integration hook (create/update/destroy) is admin-only, enforced via HookPolicy.
  # Subclasses opt in per action with `before_action :check_authorization, only: [...]`.
  def check_authorization
    authorize(:hook)
  end
end

Api::V1::Accounts::Integrations::BaseController.prepend_mod_with('Api::V1::Accounts::Integrations::BaseController')
