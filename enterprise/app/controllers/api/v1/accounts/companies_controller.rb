class Api::V1::Accounts::CompaniesController < Api::V1::Accounts::EnterpriseAccountsController
  include Sift
  sort_on :name, type: :string
  sort_on :domain, type: :string
  sort_on :created_at, type: :datetime
  sort_on :last_activity_at, internal_name: :order_on_last_activity_at, type: :scope, scope_params: [:direction]
  sort_on :contacts_count, internal_name: :order_on_contacts_count, type: :scope, scope_params: [:direction]

  RESULTS_PER_PAGE = 25

  before_action :ensure_companies_enabled!
  before_action :check_authorization
  before_action :set_current_page, only: [:index, :search]
  before_action :fetch_company, only: [:show, :update, :destroy, :avatar, :destroy_custom_attributes]

  def index
    @companies = fetch_companies(resolved_companies)
    @companies_count = @companies.total_count
  end

  def search
    if params[:q].blank?
      return render json: { error: I18n.t('errors.companies.search.query_missing') },
                    status: :unprocessable_entity
    end

    companies = resolved_companies.search_by_name_or_domain(params[:q])
    @companies = fetch_companies(companies)
    @companies_count = @companies.total_count
  end

  def show; end

  def create
    @company = Current.account.companies.build(company_params)
    @company.save!
  end

  def update
    @company.update!(company_update_params)
  end

  def destroy_custom_attributes
    custom_attributes = custom_attributes_to_destroy
    return if performed?

    @company.custom_attributes = @company.custom_attributes.excluding(*custom_attributes)
    @company.save!
  end

  def destroy
    @company.destroy!
    head :ok
  end

  def avatar
    @company.avatar.purge if @company.avatar.attached?
  end

  private

  def resolved_companies
    @resolved_companies ||= Current.account.companies
  end

  def set_current_page
    @current_page = params[:page] || 1
  end

  def fetch_companies(companies)
    filtrate(companies)
      .page(@current_page)
      .per(RESULTS_PER_PAGE)
  end

  def ensure_companies_enabled!
    return if Current.account.feature_enabled?('companies')

    render json: { error: 'Companies are not enabled for this account' }, status: :forbidden
  end

  def fetch_company
    @company = Current.account.companies.find(params[:id])
  end

  def company_params
    params.require(:company).permit(
      :name,
      :domain,
      :description,
      :avatar,
      additional_attributes: {},
      custom_attributes: {}
    )
  end

  def company_custom_attributes
    custom_attributes = company_params[:custom_attributes]
    return @company.custom_attributes.merge(custom_attributes.to_h) if custom_attributes.present?

    @company.custom_attributes
  end

  def company_update_params
    company_params.except(:custom_attributes).merge(custom_attributes: company_custom_attributes)
  end

  def custom_attributes_to_destroy
    custom_attributes = params.permit(custom_attributes: [])[:custom_attributes]
    return custom_attributes if custom_attributes.present? || params[:custom_attributes].is_a?(Array)

    render json: { error: 'custom_attributes must be an array' }, status: :unprocessable_entity
  end
end
