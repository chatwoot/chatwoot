module AttachmentConcern
  extend ActiveSupport::Concern

  def validate_and_prepare_attachments(actions, record = nil)
    blobs = []
    return [blobs, actions, nil] if actions.blank?

    sanitized = actions.map do |action|
      next action unless action[:action_name] == 'send_attachment'

      blob_id = action[:action_params].first
      blob = ActiveStorage::Blob.find_signed(blob_id.to_s)
      if blob.present?
        blobs << blob
        action.merge(action_params: [blob.id])
      elsif record && record.files.any? { |f| f.blob_id == blob_id.to_i }
        action
      else
        return [nil, nil, I18n.t('errors.attachments.invalid')]
      end
    end

    [blobs, sanitized, nil]
  end
end
