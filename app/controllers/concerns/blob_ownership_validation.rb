module BlobOwnershipValidation
  extend ActiveSupport::Concern

  private

  def attach_blob_to(attachment, blob_id:, blob_key:)
    return if blob_id.blank? || blob_key.blank?

    blob = ActiveStorage::Blob.find_by(id: blob_id, key: blob_key)
    return if blob.blank?

    return if blob.attachments.exists?

    attachment.attach(blob)
  end
end
