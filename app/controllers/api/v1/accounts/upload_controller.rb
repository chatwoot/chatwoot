class Api::V1::Accounts::UploadController < Api::V1::Accounts::BaseController
  def create
    result = if params[:attachment].present?
               create_from_file
             elsif params[:external_url].present?
               create_from_url
             else
               render_error('No file or URL provided', :unprocessable_entity)
             end

    render_success(result) if result.is_a?(ActiveStorage::Blob)
  end

  private

  def create_from_file
    attachment = params[:attachment]
    create_and_save_blob(attachment.tempfile, attachment.original_filename, attachment.content_type)
  end

  def create_from_url
    uri = parse_uri(params[:external_url])
    return if performed?

    fetch_and_process_file_from_uri(uri)
  end

  def parse_uri(url)
    uri = URI.parse(url)
    validate_uri(uri)
    uri
  rescue URI::InvalidURIError, SocketError
    render_error('Invalid URL provided', :unprocessable_entity)
    nil
  end

  def validate_uri(uri)
    raise URI::InvalidURIError unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  end

  def fetch_and_process_file_from_uri(uri)
    uri.open do |file|
      create_and_save_blob(file, File.basename(uri.path), file.content_type)
    end
  rescue OpenURI::HTTPError => e
    render_error("Failed to fetch file from URL: #{e.message}", :unprocessable_entity)
  rescue SocketError
    render_error('Invalid URL provided', :unprocessable_entity)
  rescue StandardError
    render_error('An unexpected error occurred', :internal_server_error)
  end

  def create_and_save_blob(io, filename, content_type)
    ActiveStorage::Blob.create_and_upload!(
      io: io,
      filename: filename,
      content_type: content_type
    )
  end

  def render_success(file_blob)
    render json: { file_url: url_for(file_blob), blob_key: file_blob.key, blob_id: file_blob.id }
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
