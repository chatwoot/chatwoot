module Enterprise::Concerns::CaptainFeatureGuard
  extend ActiveSupport::Concern

  private

  # Captain is a premium feature; block API access when neither the v1 nor v2 flag is enabled for the account.
  # `current_account` resolves and memoizes the account, so this does not depend on before_action ordering.
  def ensure_captain_enabled
    return if current_account.feature_enabled?('captain_integration') || current_account.feature_enabled?('captain_integration_v2')

    render json: { error: 'Captain is not enabled for this account' }, status: :forbidden
  end
end
