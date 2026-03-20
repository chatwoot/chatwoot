module AttachmentConcern
  extend ActiveSupport::Concern

  def validate_and_prepare_attachments(actions, record = nil)
    blobs = []
    return [blobs, actions, nil] if actions.blank?

    sanitized = actions.map do |action|
      next action unless attachment_action?(action)

      result = process_attachment_action(action, record, blobs)
      return [nil, nil, I18n.t('errors.attachments.invalid')] unless result

      result
    end

    [blobs, sanitized, nil]
  end

  private

  def process_attachment_action(action, record, blobs)
    blob_id = attachment_blob_id(action)
    return action if action[:action_name] == 'create_scheduled_message' && blob_id.blank?

    blob = ActiveStorage::Blob.find_signed(blob_id.to_s)

    return action.merge(action_params: attachment_action_params(action, blob.id)).tap { blobs << blob } if blob.present?
    return action if blob_already_attached?(record, blob_id)

    nil
  end

  def attachment_action?(action)
    %w[send_attachment create_scheduled_message].include?(action[:action_name])
  end

  def attachment_blob_id(action)
    return action[:action_params].first unless action[:action_name] == 'create_scheduled_message'

    params = action[:action_params].first
    params = params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
    params&.with_indifferent_access&.dig(:blob_id)
  end

  def attachment_action_params(action, blob_id)
    return [blob_id] unless action[:action_name] == 'create_scheduled_message'

    params = action[:action_params].first
    params = params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
    params = params.with_indifferent_access
    params[:blob_id] = blob_id
    [params]
  end

  def blob_already_attached?(record, blob_id)
    record&.files&.any? { |f| f.blob_id == blob_id.to_i }
  end
end
