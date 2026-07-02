class Api::V1::Accounts::Autonomia::Prospecting::BaseController < Api::V1::Accounts::BaseController
  before_action :ensure_feature_enabled
  before_action :ensure_account_administrator

  private

  def ensure_feature_enabled
    render json: { error: 'autonomia.prospecting.disabled' }, status: :not_found unless ::Autonomia::Prospecting::Config.enabled?(Current.account)
  end

  def ensure_account_administrator
    raise Pundit::NotAuthorizedError unless Current.account_user&.administrator?
  end

  def searches_scope
    ::Autonomia::Prospecting::Search.where(account: Current.account)
  end

  def leads_scope
    ::Autonomia::Prospecting::Lead.where(account: Current.account)
  end

  def lists_scope
    ::Autonomia::Prospecting::List.where(account: Current.account)
  end

  def setting
    ::Autonomia::Prospecting::Setting.for_account(Current.account)
  end
end
