class Api::V1::Accounts::UploadController < Api::V1::Accounts::BaseController
  def create
    if params[:attachment].present?
      create_from_file
    elsif params[:external_url].present?
      create_from_url
    else
      render json: { error: 'No file or URL provided' }, status: :unprocessable_entity
    end
  end

  private

  def create_from_file
    attachment = params[:attachment]
    file_blob = create_file_blob(attachment.tempfile, attachment.original_filename, attachment.content_type)
    file_blob.save!

    render_success(file_blob)
  end

  def create_from_url
    uri = parse_and_validate_uri(params[:external_url])
    return if performed?

    fetch_and_process_file_from_uri(uri)
  end

  def parse_and_validate_uri(url)
    uri = URI.parse(url)
    raise URI::InvalidURIError unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    uri
  rescue URI::InvalidURIError, SocketError
    render json: { error: 'Invalid URL provided' }, status: :unprocessable_entity
    nil
  end

  def fetch_and_process_file_from_uri(uri)
    uri.open do |file|
      file_blob = create_file_blob(file, File.basename(uri.path), file.content_type)
      file_blob.save!
      render_success(file_blob)
    end
  rescue OpenURI::HTTPError => e
    render json: { error: "Failed to fetch file from URL: #{e.message}" }, status: :unprocessable_entity
  rescue SocketError
    render json: { error: 'Invalid URL provided' }, status: :unprocessable_entity
  rescue StandardError
    render json: { error: 'An unexpected error occurred' }, status: :internal_server_error
  end

  def create_file_blob(io, filename, content_type)
    ActiveStorage::Blob.create_and_upload!(
      key: nil,
      io: io,
      filename: filename,
      content_type: content_type
    )
  end

  def render_success(file_blob)
    render json: { file_url: url_for(file_blob), blob_key: file_blob.key, blob_id: file_blob.id }
  end
end
