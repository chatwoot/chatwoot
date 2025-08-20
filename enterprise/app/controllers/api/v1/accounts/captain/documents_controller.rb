class Api::V1::Accounts::Captain::DocumentsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Captain::Assistant) }

  before_action :set_document, only: [:show, :destroy]

  RESULTS_PER_PAGE = 25

  def index
    base_query = account_documents.includes(:assistant)
    base_query = base_query.where(assistant_id: permitted_params[:assistant_id]) if permitted_params[:assistant_id].present?

    @current_page = (permitted_params[:page] || 1).to_i
    @documents_count = base_query.count
    @documents = base_query.page(@current_page).per(RESULTS_PER_PAGE)
  end

  def show; end

  def create
    @document = account_documents.build(document_params)
    @document.save!
  rescue Captain::Document::LimitExceededError => e
    render_could_not_create_error(e.message)
  rescue ActiveRecord::RecordInvalid => e
    render_could_not_create_error(e.record.errors.full_messages.join(', '))
  end

  def destroy
    @document.destroy!
    head :no_content
  end

  private

  def account_documents
    @account_documents ||= Current.account.captain_documents.ordered
  end

  def set_document
    @document = account_documents.find(permitted_params[:id])
  end

  def permitted_params
    params.permit(:assistant_id, :page, :id, :account_id)
  end

  def document_params
    params.require(:document).permit(:name, :external_link, :assistant_id, :pdf_file)
  end
end
