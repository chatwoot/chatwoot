class Api::V1::Accounts::Captain::DocumentsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Captain::Assistant) }

  before_action :set_current_page, only: [:index]
  before_action :set_documents, except: [:create, :upload_pdf]
  before_action :set_document, only: [:show, :destroy]
  before_action :set_assistant, only: [:create, :upload_pdf]
  RESULTS_PER_PAGE = 25

  def index
    base_query = @documents
    base_query = base_query.where(assistant_id: permitted_params[:assistant_id]) if permitted_params[:assistant_id].present?

    @documents_count = base_query.count
    @documents = base_query.page(@current_page).per(RESULTS_PER_PAGE)
  end

  def show; end

  def create
    return render_could_not_create_error('Missing Assistant') if @assistant.nil?

    @document = @assistant.documents.build(document_params)

    # Handle PDF file upload if present
    @document.pdf_file.attach(document_params[:pdf_file]) if document_params[:pdf_file].present?

    @document.save!
  rescue Captain::Document::LimitExceededError => e
    render_could_not_create_error(e.message)
  rescue StandardError => e
    Rails.logger.error "Document creation error: #{e.message}"
    render_could_not_create_error('Failed to create document')
  end

  def upload_pdf
    pdf_file = params[:pdf_file]

    return render_could_not_create_error('PDF file is required') if pdf_file.blank?
    return render_could_not_create_error('Invalid file type') unless valid_pdf?(pdf_file)
    return render_could_not_create_error('File too large (max 512MB)') if pdf_file.size > 512.megabytes
    return render_could_not_create_error('Missing Assistant') if @assistant.nil?

    create_pdf_document(pdf_file)
    render :show
  rescue Captain::Document::LimitExceededError => e
    render_could_not_create_error(e.message)
  rescue StandardError => e
    Rails.logger.error "PDF upload error: #{e.message}"
    render_could_not_create_error('Failed to upload PDF')
  end

  def destroy
    @document.destroy
    head :no_content
  end

  private

  def set_documents
    @documents = Current.account.captain_documents.includes(:assistant).ordered
  end

  def set_document
    @document = @documents.find(permitted_params[:id])
  end

  def set_assistant
    assistant_id = document_params[:assistant_id] || params[:assistant_id]
    @assistant = Current.account.captain_assistants.find_by(id: assistant_id)
  end

  def set_current_page
    @current_page = permitted_params[:page] || 1
  end

  def permitted_params
    params.permit(:assistant_id, :page, :id, :account_id)
  end

  def document_params
    params.require(:document).permit(:name, :external_link, :assistant_id, :pdf_file)
  end

  def valid_pdf?(file)
    file.content_type == 'application/pdf'
  end

  def create_pdf_document(pdf_file)
    @document = @assistant.documents.build(
      name: pdf_file.original_filename,
      account: Current.account
    )
    @document.pdf_file.attach(pdf_file)
    @document.save!
  end
end
