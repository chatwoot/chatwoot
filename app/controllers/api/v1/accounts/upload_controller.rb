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
    file_blob = ActiveStorage::Blob.create_and_upload!(
      key: nil,
      io: attachment.tempfile,
      filename: attachment.original_filename,
      content_type: attachment.content_type
    )
    file_blob.save!

    render_success(file_blob)
  end

  def create_from_url
    external_url = params[:external_url]

    begin
      uri = URI.parse(external_url)
      raise URI::InvalidURIError unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

      uri.open do |file|
        filename = File.basename(uri.path)
        content_type = file.content_type

        file_blob = ActiveStorage::Blob.create_and_upload!(
          key: nil,
          io: file,
          filename: filename,
          content_type: content_type
        )
        file_blob.save!

        render_success(file_blob)
      end
    rescue URI::InvalidURIError, SocketError => e
      render json: { error: 'Invalid URL provided' }, status: :unprocessable_entity
    rescue OpenURI::HTTPError => e
      render json: { error: "Failed to fetch file from URL: #{e.message}" }, status: :unprocessable_entity
    rescue StandardError => e
      render json: { error: 'An unexpected error occurred' }, status: :internal_server_error
    end
  end

  def render_success(file_blob)
    render json: { file_url: url_for(file_blob), blob_key: file_blob.key, blob_id: file_blob.id }
  end
end
