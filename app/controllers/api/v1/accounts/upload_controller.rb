class Api::V1::Accounts::UploadController < Api::V1::Accounts::BaseController
  def create
    file_blob = ActiveStorage::Blob.create_and_upload!(
      key: nil,
      io: params[:attachment].tempfile,
      filename: params[:attachment].original_filename,
      content_type: params[:attachment].content_type
    )
    file_blob.save!

    render json: { file_url: url_for(file_blob), blob_key: file_blob.key, blob_id: file_blob.id }
  end
end
