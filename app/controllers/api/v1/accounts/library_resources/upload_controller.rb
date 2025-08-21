class Api::V1::Accounts::LibraryResources::UploadController < Api::V1::Accounts::BaseController
  def create
    result = if params[:attachment].present?
               create_from_file
             else
               render_error('No file provided', :unprocessable_entity)
             end

    render_success(result) if result.is_a?(ActiveStorage::Blob)
  end

  private

  def create_from_file
    attachment = params[:attachment]
    validate_file_type(attachment.content_type)
    return if performed?

    create_and_save_blob(attachment.tempfile, attachment.original_filename, attachment.content_type)
  end

  def validate_file_type(content_type)
    allowed_types = [
      'image/jpeg', 'image/png', 'image/gif', 'image/webp',
      'video/mp4', 'video/mpeg', 'video/quicktime', 'video/webm',
      'audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp3',
      'application/pdf'
    ]

    return if allowed_types.include?(content_type)

    render_error('File type not supported for library resources', :unprocessable_entity)
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
