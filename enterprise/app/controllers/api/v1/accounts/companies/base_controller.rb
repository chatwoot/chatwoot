class Api::V1::Accounts::Companies::BaseController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :ensure_companies_enabled!
  before_action :fetch_company

  private

  def ensure_companies_enabled!
    return if Current.account.feature_enabled?('companies')

    render json: { error: 'Companies are not enabled for this account' }, status: :forbidden
  end

  def fetch_company
    @company = Current.account.companies.find(params[:company_id])
  end

  def authorize_company_read!
    authorize(@company, :show?)
  end

  def authorize_company_update!
    authorize(@company, :update?)
  end
end
