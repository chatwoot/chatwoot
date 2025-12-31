# frozen_string_literal: true

class Api::V1::Accounts::Aloo::DocumentsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_assistant
  before_action :set_document, except: %i[index create]

  # Allowed file types for upload
  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
    text/plain
    text/markdown
    text/csv
  ].freeze

  MAX_FILE_SIZE = 10.megabytes

  def index
    @documents = @assistant.documents.order(created_at: :desc)
    render json: @documents.map { |d| document_json(d) }
  end

  def show
    render json: document_json(@document)
  end

  def create
    validate_file!

    @document = @assistant.documents.create!(
      account: Current.account,
      title: document_params[:title] || file_title,
      source_type: 'file',
      file: document_params[:file],
      metadata: {
        original_filename: document_params[:file].original_filename,
        content_type: document_params[:file].content_type
      }
    )

    # Queue processing job
    Aloo::ProcessDocumentJob.perform_later(@document.id)

    render json: document_json(@document), status: :created
  end

  def destroy
    @document.destroy!
    head :ok
  end

  # POST /api/v1/accounts/:account_id/aloo/assistants/:assistant_id/documents/:id/reprocess
  def reprocess
    @document.update!(status: 'pending')
    Aloo::ProcessDocumentJob.perform_later(@document.id)
    render json: { message: 'Document queued for reprocessing' }
  end

  private

  def set_assistant
    @assistant = Current.account.aloo_assistants.find(params[:assistant_id])
  end

  def set_document
    @document = @assistant.documents.find(params[:id])
  end

  def document_params
    params.permit(:title, :file)
  end

  def validate_file!
    file = document_params[:file]

    raise ActionController::ParameterMissing, 'file is required' unless file

    unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
      raise ActionController::BadRequest.new("Unsupported file type: #{file.content_type}")
    end

    if file.size > MAX_FILE_SIZE
      raise ActionController::BadRequest.new("File too large. Maximum size is #{MAX_FILE_SIZE / 1.megabyte}MB")
    end
  end

  def file_title
    filename = document_params[:file].original_filename
    File.basename(filename, File.extname(filename)).titleize
  end

  def document_json(document)
    {
      id: document.id,
      title: document.title,
      source_type: document.source_type,
      status: document.status,
      filename: document.file.attached? ? document.file.filename.to_s : nil,
      file_size: document.file.attached? ? document.file.byte_size : nil,
      content_type: document.metadata&.dig('content_type'),
      chunk_count: document.embeddings.count,
      processed_at: document.processed_at,
      created_at: document.created_at,
      updated_at: document.updated_at
    }
  end

  def check_authorization
    authorize(Current.account, :update?)
  end
end
