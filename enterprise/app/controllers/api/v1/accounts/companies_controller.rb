class Api::V1::Accounts::CompaniesController < Api::V1::Accounts::EnterpriseAccountsController
  include Sift
  sort_on :name, type: :string
  sort_on :domain, type: :string
  sort_on :created_at, type: :datetime
  sort_on :contacts_count, internal_name: :order_on_contacts_count, type: :scope, scope_params: [:direction]

  RESULTS_PER_PAGE = 25

  before_action :authorize_collection!, only: [:index, :search, :create]
  before_action :set_current_page, only: [:index, :search, :contacts]
  before_action :set_include_contact_inboxes, only: [:contacts]
  before_action :fetch_company, only: [:show, :update, :destroy, :contacts]
  before_action :authorize_company!, only: [:show, :update, :destroy, :contacts]

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

  def contacts
    includes_hash = { avatar_attachment: [:blob], company: [] }
    includes_hash[:contact_inboxes] = { inbox: :channel } if @include_contact_inboxes

    @contacts = @company.contacts
                        .includes(includes_hash)
                        .page(@current_page)
                        .per(Api::V1::Accounts::ContactsController::RESULTS_PER_PAGE)
    @contacts_count = @contacts.total_count
  end

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

  def authorize_collection!
    raise Pundit::NotAuthorizedError unless ChatwootApp.enterprise?

    authorize(Company, "#{action_name}?".to_sym)
  end

  def fetch_company
    @company = Current.account.companies.find(params[:id])
  end

  def authorize_company!
    authorize(@company, policy_action)
  end

  def policy_action
    return :show? if action_name == 'contacts'

    "#{action_name}?".to_sym
  end

  def set_include_contact_inboxes
    @include_contact_inboxes = if params[:include_contact_inboxes].present?
                                 params[:include_contact_inboxes] == 'true'
                               else
                                 true
                               end
  end

  def company_params
    params.require(:company).permit(:name, :domain, :description, :avatar)
  end
end
