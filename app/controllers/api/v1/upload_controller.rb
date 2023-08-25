class Api::V1::UploadController < ApplicationController
  def create
    file_blob = ActiveStorage::Blob.create_and_upload!(
      key: nil,
      io: params[:attachment].tempfile,
      filename: params[:attachment].original_filename,
      content_type: params[:attachment].content_type
    )
    file_blob.save!
    render json: { file_url: url_for(file_blob) }
  end
end
