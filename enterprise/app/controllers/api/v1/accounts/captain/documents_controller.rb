class Api::V1::Accounts::Captain::DocumentsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Captain::Assistant) }

  before_action :set_current_page, only: [:index]
  before_action :set_documents, except: [:create]
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
    @document.save!
  rescue Captain::Document::LimitExceededError => e
    render_could_not_create_error(e.message)
  end

  def upload_pdf
    return render_could_not_create_error('Missing Assistant') if @assistant.nil?
    return render_could_not_create_error('No PDF file provided') unless pdf_file_present?
    
    # Validate PDF file
    return render_could_not_create_error('Invalid file type. Only PDF files are allowed.') unless valid_pdf_file?
    return render_could_not_create_error('File size too large. Maximum size is 10MB.') unless valid_pdf_size?
    
    # Upload PDF to storage and get URL
    blob = create_pdf_blob
    pdf_url = Rails.application.routes.url_helpers.rails_blob_url(blob, host: ENV.fetch('FRONTEND_URL', 'http://localhost:3000'))
    
    # Create document with PDF URL
    @document = @assistant.documents.build(
      name: pdf_params[:pdf_document].original_filename.gsub('.pdf', ''),
      external_link: pdf_url
    )
    @document.save!
    
    render json: { 
      document: @document.as_json(only: [:id, :name, :status, :created_at]),
      message: 'PDF uploaded successfully. Processing will begin shortly.'
    }
  rescue Captain::Document::LimitExceededError => e
    render_could_not_create_error(e.message)
  rescue StandardError => e
    render_could_not_create_error("PDF upload failed: #{e.message}")
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
    assistant_id = action_name == 'upload_pdf' ? pdf_params[:assistant_id] : document_params[:assistant_id]
    @assistant = Current.account.captain_assistants.find_by(id: assistant_id)
  end

  def set_current_page
    @current_page = permitted_params[:page] || 1
  end

  def permitted_params
    params.permit(:assistant_id, :page, :id, :account_id)
  end

  def document_params
    params.require(:document).permit(:name, :external_link, :assistant_id)
  end

  def pdf_params
    params.permit(:pdf_document, :assistant_id)
  end

  def pdf_file_present?
    pdf_params[:pdf_document].present?
  end

  def valid_pdf_file?
    return false unless pdf_params[:pdf_document].respond_to?(:content_type)
    
    pdf_params[:pdf_document].content_type == 'application/pdf'
  end

  def valid_pdf_size?
    return false unless pdf_params[:pdf_document].respond_to?(:size)
    
    pdf_params[:pdf_document].size <= 10.megabytes
  end

  def create_pdf_blob
    ActiveStorage::Blob.create_and_upload!(
      io: pdf_params[:pdf_document].tempfile,
      filename: pdf_params[:pdf_document].original_filename,
      content_type: pdf_params[:pdf_document].content_type
    )
  end
end
