class Api::V1::Accounts::CompaniesController < Api::V1::Accounts::EnterpriseAccountsController
  include Sift
  sort_on :name, type: :string
  sort_on :domain, type: :string
  sort_on :created_at, type: :datetime

  RESULTS_PER_PAGE = 25

  before_action :check_authorization
  before_action :set_current_page, only: [:index]
  before_action :fetch_company, only: [:show, :update, :destroy]

  def index
    @companies = fetch_companies(resolved_companies)
    @companies_count = @companies.total_count
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

  def resolved_companies
    return @resolved_companies if @resolved_companies

    @resolved_companies = Current.account.companies
    if params[:search].present?
      @resolved_companies = @resolved_companies.where(
        'name ILIKE :search OR domain ILIKE :search',
        search: "%#{params[:search]}%"
      )
    end
    @resolved_companies
  end

  def set_current_page
    @current_page = params[:page] || 1
  end

  def fetch_companies(companies)
    filtrate(companies)
      .page(@current_page)
      .per(RESULTS_PER_PAGE)
  end

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
