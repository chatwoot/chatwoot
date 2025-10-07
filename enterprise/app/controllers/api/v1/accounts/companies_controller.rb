class Api::V1::Accounts::CompaniesController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :check_authorization
  before_action :fetch_company, only: [:show, :update, :destroy]

  def index
    @companies = Current.account.companies.ordered_by_name
  end

  def show; end

  def create
    @company = Current.account.companies.build(company_params)
    @company.save!
  end

  def update
    @company.update!(company_params)
  end

  def destroy
    @company.destroy!
    head :ok
  end

  private

  def check_authorization
    raise Pundit::NotAuthorizedError unless ChatwootApp.enterprise?

    authorize(Company)
  end

  def fetch_company
    @company = Current.account.companies.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name, :domain, :description, :avatar)
  end
end
