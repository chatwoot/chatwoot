module AttachmentConcern
  MODEL_TYPE = %w[CannedResponse Message].freeze

  private

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def process_attachments_to_be_added(resource:, call_remove_handler: false, params: {})
    @attachments = params[:attachments]
    process_attachments_to_be_removed(resource: resource, params: params) if call_remove_handler
    return if @attachments.blank? || MODEL_TYPE.exclude?(resource.class.name)

    old_attachments_of_resource_ids = old_attachments_of_resource_ids(resource)

    @attachments.reject { |i| i.is_a?(String) && old_attachments_of_resource_ids.include?(i) }
                .each do |uploaded_attachment|
      if uploaded_attachment.is_a?(String)
        attach_blob(resource, uploaded_attachment)
      else
        upload_raw_file(resource, uploaded_attachment)
      end
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def process_attachments_to_be_removed(resource:, params: {})
    submitted_attachments = params[:attachments] || []
    old_attachments_of_resource = current_records_to_updated(resource)
    return if old_attachments_of_resource.blank?

    attachments_to_be_deleted = old_attachments_of_resource.select do |attachment|
      submitted_attachments
        .reject { |i| i.is_a?(ActionDispatch::Http::UploadedFile) }
        .exclude?(attachment.file_blob.signed_id)
    end

    attachments_to_be_deleted.each(&:destroy!) if attachments_to_be_deleted.present?
  end

  def attach_blob(resource, blob_signed_id)
    attachment = build_attachment(
      resource,
      {
        account_id: resource.account_id
      }
    )
    # Attach to the file blob
    blob = ActiveStorage::Blob.find_signed(blob_signed_id)
    attachment.file.attach(blob)
    # Assign value of File Type
    attachment.file_type = file_type_by_signed_id(blob_signed_id)
  end

  def upload_raw_file(resource, uploaded_attachment)
    filename = I18n.transliterate(uploaded_attachment.original_filename)
    filename = filename.gsub(/[?]/, '')
    uploaded_attachment.original_filename = filename
    attachment = build_attachment(
      resource,
      {
        account_id: resource.account_id,
        file: uploaded_attachment
      }
    )
    # Assign value of File Type
    attachment.file_type = file_type(uploaded_attachment.content_type)
  end

  def build_attachment(resource, attachment_attributes)
    current_model = resource.class.name

    case current_model
    when 'Message'
      resource.attachments.build(**attachment_attributes)
    when 'CannedResponse'
      resource.canned_attachments.build(**attachment_attributes)
    else
      raise "Unsupported operation for this resource: #{current_model}"
    end
  end

  def old_attachments_of_resource_ids(resource)
    return [] unless resource.instance_of?(::CannedResponse) && !resource.new_record?

    old_attachments_of_resource = current_records_to_updated(resource)

    old_attachments_of_resource.map { |attachment| attachment.file_blob.signed_id }
  end

  def current_records_to_updated(resource)
    current_model = resource.class.name

    case current_model
    when 'Message'
      resource.reload.attachments
    when 'CannedResponse'
      resource.reload.canned_attachments
    else
      raise "Unsupported operation for this resource: #{current_model}"
    end
  end
end
