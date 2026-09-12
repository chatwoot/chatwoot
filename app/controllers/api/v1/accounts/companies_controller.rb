class Api::V1::Accounts::CompaniesController < Api::V1::Accounts::BaseController
  before_action :fetch_company, except: [:index, :create]
  before_action :check_authorization

  def index
    @companies = policy_scope(Current.account.companies)
  end

  def show; end

  def create
    @company = Current.account.companies.create!(permitted_params)
  end

  def update
    @company.update!(permitted_params)
  end

  def destroy
    @company.destroy!
    head :ok
  end

  private

  def fetch_company
    @company = Current.account.companies.find(params[:id])
  end

  def permitted_params
    params.require(:company).permit(
      :name, :email, :phone, :website, :description,
      custom_attributes: {}
    )
  end
end
