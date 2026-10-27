module MailboxTnefHelper
  TNEF_MIME_TYPES = %w[application/ms-tnef application/vnd.ms-tnef].freeze

  private

  # Outlook can wrap the real attachments in a single winmail.dat (TNEF) part.
  # Replace it with the files it contains; keep it as is when nothing can be extracted.
  def expand_tnef_attachments(attachments)
    limit = Message::NUMBER_OF_PERMITTED_ATTACHMENTS
    expanded = []
    attachments.each_with_index do |mail_attachment, index|
      # every attachment after this one keeps a slot, so a part never uploads more than can be attached
      slots = limit - expanded.size - (attachments.size - index - 1)
      expanded.concat(expand_tnef_attachment(mail_attachment, slots))
    end
    expanded.first([expanded.size - limit, 0].max).each { |mail_attachment| mail_attachment[:blob].purge }
    expanded.last(limit)
  end

  def expand_tnef_attachment(mail_attachment, slots)
    return [mail_attachment] unless slots.positive? && TNEF_MIME_TYPES.include?(mail_attachment[:original].mime_type.to_s.downcase)

    files = extract_tnef_files(mail_attachment[:blob], slots)
    return [mail_attachment] if files.empty?

    # the winmail.dat blob was stored by MailPresenter and is no longer attached anywhere
    mail_attachment[:blob].purge
    files
  end

  def extract_tnef_files(blob, slots)
    # only the files that can still be attached are uploaded
    TnefReader.files(blob.download).last(slots).map do |file|
      { blob: ActiveStorage::Blob.create_and_upload!(io: StringIO.new(file.data), filename: file.name) }
    end
  rescue TnefReader::Error => e
    Rails.logger.error "[MailboxHelper] Could not extract TNEF attachment for message with ID: #{processed_mail.message_id}: #{e.message}"
    []
  end
end
