module FileUploadHelpers
  def get_blob_for(file_path, content_type)
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(file_path, 'rb'),
      filename: File.basename(file_path),
      content_type: content_type
    )
  end
end
