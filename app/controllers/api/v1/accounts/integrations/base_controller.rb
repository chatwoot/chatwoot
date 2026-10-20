class Api::V1::Accounts::Integrations::BaseController < Api::V1::Accounts::BaseController
  private

  # Managing an integration hook (create/update/destroy) is admin-only, enforced via HookPolicy.
  # Subclasses opt in per action with `before_action :check_authorization, only: [...]`.
  def check_authorization
    authorize(:hook)
  end
end

Api::V1::Accounts::Integrations::BaseController.prepend_mod_with('Api::V1::Accounts::Integrations::BaseController')
