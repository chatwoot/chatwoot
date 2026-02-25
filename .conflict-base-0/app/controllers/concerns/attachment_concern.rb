module AttachmentConcern
  extend ActiveSupport::Concern

  def validate_and_prepare_attachments(actions, record = nil)
    blobs = []
    return [blobs, actions, nil] if actions.blank?

    sanitized = actions.map do |action|
      next action unless action[:action_name] == 'send_attachment'

      result = process_attachment_action(action, record, blobs)
      return [nil, nil, I18n.t('errors.attachments.invalid')] unless result

      result
    end

    [blobs, sanitized, nil]
  end

  private

  def process_attachment_action(action, record, blobs)
    blob_id = action[:action_params].first
    blob = ActiveStorage::Blob.find_signed(blob_id.to_s)

    return action.merge(action_params: [blob.id]).tap { blobs << blob } if blob.present?
    return action if blob_already_attached?(record, blob_id)

    nil
  end

  def blob_already_attached?(record, blob_id)
    record&.files&.any? { |f| f.blob_id == blob_id.to_i }
  end
end
