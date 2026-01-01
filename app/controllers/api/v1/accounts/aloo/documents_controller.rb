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
    if document_params[:source_url].present?
      create_website_document
    else
      create_file_document
    end
  end

  def destroy
    @document.destroy!
    head :ok
  end

  def reprocess
    @document.update!(status: 'pending')
    Aloo::ProcessDocumentJob.perform_later(@document.id)
    render json: { message: 'Document queued for reprocessing' }
  end

  private

  def create_file_document
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

    Aloo::ProcessDocumentJob.perform_later(@document.id)
    render json: document_json(@document), status: :created
  end

  def create_website_document
    validate_url!

    @document = @assistant.documents.create!(
      account: Current.account,
      title: document_params[:title] || extract_title_from_url,
      source_type: 'website',
      source_url: document_params[:source_url],
      metadata: {
        crawl_full_site: ActiveModel::Type::Boolean.new.cast(document_params[:crawl_full_site])
      }
    )

    Aloo::ProcessDocumentJob.perform_later(@document.id)
    render json: document_json(@document), status: :created
  end

  def validate_url!
    url = document_params[:source_url]
    raise ActionController::BadRequest.new('URL is required') if url.blank?

    uri = URI.parse(url)
    raise ActionController::BadRequest.new('Invalid URL format') unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    # Check for duplicate URL
    normalized_url = normalize_url(url)
    existing = @assistant.documents.where(source_type: 'website').find do |doc|
      normalize_url(doc.source_url) == normalized_url
    end
    raise ActionController::BadRequest.new('This URL has already been added') if existing
  rescue URI::InvalidURIError
    raise ActionController::BadRequest.new('Invalid URL format')
  end

  def normalize_url(url)
    uri = URI.parse(url)
    # Normalize: lowercase host, remove www, remove trailing slash, remove fragment
    host = uri.host&.downcase&.gsub(/^www\./, '')
    path = uri.path&.gsub(%r{/+$}, '')
    path = '/' if path.blank?
    "#{host}#{path}"
  rescue URI::InvalidURIError
    url
  end

  def extract_title_from_url
    URI.parse(document_params[:source_url]).host&.gsub(/^www\./, '') || 'Website'
  rescue URI::InvalidURIError
    'Website'
  end

  def set_assistant
    @assistant = Current.account.aloo_assistants.find(params[:assistant_id])
  end

  def set_document
    @document = @assistant.documents.find(params[:id])
  end

  def document_params
    params.permit(:title, :file, :source_url, :crawl_full_site)
  end

  def validate_file!
    file = document_params[:file]

    raise ActionController::ParameterMissing, 'file is required' unless file

    raise ActionController::BadRequest.new("Unsupported file type: #{file.content_type}") unless ALLOWED_CONTENT_TYPES.include?(file.content_type)

    return unless file.size > MAX_FILE_SIZE

    raise ActionController::BadRequest.new("File too large. Maximum size is #{MAX_FILE_SIZE / 1.megabyte}MB")
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
      source_url: document.source_url,
      status: document.status,
      filename: document.file.attached? ? document.file.filename.to_s : nil,
      file_size: document.file.attached? ? document.file.byte_size : nil,
      content_type: document.metadata&.dig('content_type'),
      pages_scraped: document.metadata&.dig('pages_scraped'),
      crawl_full_site: document.metadata&.dig('crawl_full_site'),
      chunk_count: document.embeddings.count,
      created_at: document.created_at,
      updated_at: document.updated_at
    }
  end

  def check_authorization
    authorize(Current.account, :update?)
  end
end
