class Api::V1::Accounts::ResponseSourcesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :check_authorization
  before_action :find_document, except: [:index, :create, :bulk_create, :search]
  before_action :set_current_page, only: [:index, :search]

  RESULTS_PER_PAGE = 25

  def index
    @documents = account.response_documents.page(@current_page).per(RESULTS_PER_PAGE).order(created_at: :desc)
    @documents_count = account.response_documents.count
  end

  def search
    documents = account.response_documents.where('external_link ILIKE :query', query: "%#{params[:query]}%")
    @documents = documents.page(@current_page).per(RESULTS_PER_PAGE) if documents.present?
    @documents_count = documents.count
  end

  def show
    render json: @document
  end

  def create
    document = account.response_documents.new(document_params)
    if document.save
      render json: document, status: :created
    else
      render json: { errors: document.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def bulk_create
    documents = params[:external_links].map do |doc_params|
      account.response_documents.new(doc_params.permit(:name, :external_link).merge(assistant_id: params[:assistant_id]))
    end

    documents.each do |document|
      render json: { errors: document.errors.full_messages }, status: :unprocessable_entity and return unless document.save
    end

    render json: documents, status: :created
  end

  def update
    if @document.update(document_params.except(:assistant_id, :external_link))
      render json: @document
    else
      render json: { errors: @document.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @document.destroy
    head :no_content
  end

  def responses
    render json: @document.responses
  end

  private

  def find_document
    @document = account.response_documents.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:name, :content, :external_link, :assistant_id, external_links: [:name, :external_link])
  end

  def set_current_page
    @current_page = params[:page] || 1
  end
end
