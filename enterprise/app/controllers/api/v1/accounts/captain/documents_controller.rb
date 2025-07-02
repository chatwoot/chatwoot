class Api::V1::Accounts::Captain::DocumentsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Captain::Assistant) }

  before_action :set_current_page, only: [:index]
  before_action :set_documents, except: [:create]
  before_action :set_document, only: [:show, :destroy]
  before_action :set_assistant, only: [:create, :upload_pdf]

  RESULTS_PER_PAGE = 25
  # Fixed PDF size limit
  MAX_PDF_SIZE = 25.megabytes
  ALLOWED_PDF_CONTENT_TYPES = ['application/pdf'].freeze
  PDF_MAGIC_NUMBERS = ['%PDF'].freeze

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
    validation_errors = validate_upload_prerequisites
    return render_could_not_create_error(validation_errors) if validation_errors

    process_pdf_upload
  rescue Captain::Document::LimitExceededError => e
    handle_limit_exceeded_error(e)
  rescue ActiveStorage::FileNotFoundError => e
    handle_file_not_found_error(e)
  rescue StandardError => e
    handle_general_upload_error(e)
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

  def validate_pdf_file
    file = pdf_params[:pdf_document]

    file_object_error = validate_file_object(file)
    return file_object_error if file_object_error

    file_type_error = validate_file_type(file)
    return file_type_error if file_type_error

    file_size_error = validate_file_size(file)
    return file_size_error if file_size_error

    { valid: true }
  end

  def validate_file_object(file)
    return nil if file.respond_to?(:content_type) && file.respond_to?(:size)

    { valid: false, error: 'Invalid file object' }
  end

  def validate_file_type(file)
    return nil if ALLOWED_PDF_CONTENT_TYPES.include?(file.content_type)

    { valid: false, error: 'Invalid file type. Only PDF files are allowed.' }
  end

  def validate_file_size(file)
    return nil if file.size <= MAX_PDF_SIZE

    { valid: false, error: "File size too large. Maximum size is #{MAX_PDF_SIZE / 1.megabyte}MB." }
  end

  def create_pdf_blob
    file = pdf_params[:pdf_document]

    ActiveStorage::Blob.create_and_upload!(
      io: file.tempfile,
      filename: sanitize_filename(file.original_filename),
      content_type: file.content_type,
      metadata: {
        uploaded_by: Current.user&.id,
        assistant_id: @assistant.id,
        account_id: Current.account.id,
        original_filename: file.original_filename
      }
    )
  rescue StandardError => e
    Rails.logger.error "Failed to create PDF blob: #{e.message}"
    raise ActiveStorage::FileNotFoundError, 'Failed to upload PDF file'
  end

  def generate_pdf_url(blob)
    Rails.application.routes.url_helpers.rails_blob_url(
      blob,
      host: ENV.fetch('FRONTEND_URL') { Rails.application.config.action_mailer.default_url_options[:host] }
    )
  end

  def sanitize_filename(filename)
    return 'document' if filename.blank?

    base_name = File.basename(filename, '.pdf')
    sanitized = base_name.gsub(/[^\w\s.-]/, '').strip.squeeze(' ')
    (sanitized.presence || 'document')
  end

  def process_pdf_upload
    ActiveRecord::Base.transaction do
      blob = create_pdf_blob
      pdf_url = generate_pdf_url(blob)

      @document = @assistant.documents.build(
        name: sanitize_filename(pdf_params[:pdf_document].original_filename),
        external_link: pdf_url,
        source_type: 'pdf_upload',
        content_type: pdf_params[:pdf_document].content_type,
        file_size: pdf_params[:pdf_document].size
      )
      @document.save!

      log_pdf_upload_success

      # Use the same response structure as create action for consistency
      render :create
    end
  end

  def log_pdf_upload_success
    Rails.logger.info "PDF uploaded successfully - Document ID: #{@document.id}, Assistant ID: #{@assistant.id}, Account ID: #{Current.account.id}"
  end

  def validate_upload_prerequisites
    return 'Missing Assistant' if @assistant.nil?
    return 'No PDF file provided' unless pdf_file_present?

    validation_result = validate_pdf_file
    return validation_result[:error] unless validation_result[:valid]

    nil
  end

  def handle_limit_exceeded_error(error)
    Rails.logger.warn "Document limit exceeded for assistant #{@assistant.id}: #{error.message}"
    render_could_not_create_error(error.message)
  end

  def handle_file_not_found_error(error)
    Rails.logger.error "PDF file not found during upload: #{error.message}"
    render_could_not_create_error('PDF file could not be processed. Please try again.')
  end

  def handle_general_upload_error(error)
    Rails.logger.error "PDF upload failed for assistant #{@assistant&.id}: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    render_could_not_create_error('PDF upload failed. Please try again.')
  end
end
