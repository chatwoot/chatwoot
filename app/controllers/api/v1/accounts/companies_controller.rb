# Restore the Companies feature (dropped with enterprise edition).
# Mirrors the original Chatwoot Companies API surface so the existing
# dashboard Companies UI (routes/dashboard/companies/*) works again.
class Api::V1::Accounts::CompaniesController < Api::V1::Accounts::BaseController
  before_action :company, except: [:index, :create, :search]
  before_action :check_authorization

  def index
    @companies = Current.account.companies.search(params.permit![:q]).page(current_page).per(RESULTS_PER_PAGE)
  end

  def search
    render json: { error: 'Specify search string with parameter q' }, status: :unprocessable_entity and return if params[:q].blank?

    @companies = Current.account.companies.search(params.permit![:q]).page(current_page).per(RESULTS_PER_PAGE)
    render 'index'
  end

  def show; end

  def create
    @company = Current.account.companies.create!(company_params)
  end

  def update
    @company.update!(company_params)
  end

  def destroy
    @company.destroy!
    head :ok
  end

  def destroy_custom_attributes
    @company.custom_attributes = @company.custom_attributes.excluding(params[:custom_attributes])
    @company.save!
    render 'show'
  end

  def avatar
    @company.avatar.purge if @company.avatar.attached?
    @company
  end

  private

  RESULTS_PER_PAGE = 15

  def current_page
    params[:page] || 1
  end

  def company
    @company ||= Current.account.companies.find(params[:id])
  end

  def company_params
    params.require(:company).permit(
      :name, :domain, :description, :avatar,
      additional_attributes: {}, custom_attributes: {}
    )
  end
end
