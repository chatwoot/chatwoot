module MailboxTnefHelper
  private

  TNEF_MIME_TYPES = %w[application/ms-tnef application/vnd.ms-tnef].freeze

  # Outlook can wrap the real attachments in a single winmail.dat (TNEF) part.
  # Replace it with the files it contains; keep it as is when nothing can be extracted.
  def expand_tnef_attachments(attachments)
    expanded = attachments.flat_map { |mail_attachment| expand_tnef_attachment(mail_attachment) }
    limit = Message::NUMBER_OF_PERMITTED_ATTACHMENTS
    expanded.first([expanded.size - limit, 0].max).each { |mail_attachment| mail_attachment[:blob].purge }
    expanded.last(limit)
  end

  def expand_tnef_attachment(mail_attachment)
    return [mail_attachment] unless TNEF_MIME_TYPES.include?(mail_attachment[:original].mime_type.to_s.downcase)

    files = extract_tnef_files(mail_attachment[:blob])
    return [mail_attachment] if files.empty?

    # the winmail.dat blob was stored by MailPresenter and is no longer attached anywhere
    mail_attachment[:blob].purge
    files
  end

  # Runs the tnef binary shipped with the gem. Tnef.unpack changes the working directory
  # of the whole process, which is not safe with concurrent Sidekiq threads.
  def extract_tnef_files(blob)
    Dir.mktmpdir do |dir|
      _output, error, status = Open3.capture3(Tnef::Executable.path, '--number-backups', '-K', '-C', dir, stdin_data: blob.download, binmode: true)
      raise IOError, error unless status.success?

      # only the files that can still be attached are uploaded
      Dir.children(dir).sort.last(Message::NUMBER_OF_PERMITTED_ATTACHMENTS).map do |name|
        File.open(File.join(dir, name)) { |file| { blob: ActiveStorage::Blob.create_and_upload!(io: file, filename: name) } }
      end
    end
  rescue IOError, SystemCallError => e
    Rails.logger.error "[MailboxHelper] Could not extract TNEF attachment for message with ID: #{processed_mail.message_id}: #{e.message}"
    []
  end
end
