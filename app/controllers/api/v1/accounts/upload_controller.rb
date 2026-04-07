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
    SafeFetch.fetch(params[:external_url].to_s) do |result|
      create_and_save_blob(result.tempfile, result.filename, result.content_type)
    end
  rescue SafeFetch::HttpError => e
    render_error("Failed to fetch file from URL: #{e.message}", :unprocessable_entity)
  rescue SafeFetch::Error
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
    render json: { file_url: url_for(file_blob), blob_id: file_blob.signed_id }
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
