module MailboxTnefHelper
  private

  # Outlook can wrap the real attachments in a single winmail.dat (TNEF) part.
  # Replace it with the files it contains; keep it as is when nothing can be extracted.
  def expand_tnef_attachments(attachments)
    attachments.flat_map do |mail_attachment|
      next mail_attachment unless mail_attachment[:original].mime_type == 'application/ms-tnef'

      extract_tnef_files(mail_attachment[:blob]).presence || mail_attachment
    end.last(Message::NUMBER_OF_PERMITTED_ATTACHMENTS)
  end

  # Runs the tnef binary shipped with the gem. Tnef.unpack changes the working directory
  # of the whole process, which is not safe with concurrent Sidekiq threads.
  def extract_tnef_files(blob)
    Dir.mktmpdir do |dir|
      _output, error, status = Open3.capture3(Tnef::Executable.path, '--number-backups', '-K', '-C', dir, stdin_data: blob.download, binmode: true)
      raise IOError, error unless status.success?

      Dir.children(dir).sort.map do |name|
        File.open(File.join(dir, name)) { |file| { blob: ActiveStorage::Blob.create_and_upload!(io: file, filename: name) } }
      end
    end
  rescue IOError, SystemCallError => e
    Rails.logger.error "[MailboxHelper] Could not extract TNEF attachment for message with ID: #{processed_mail.message_id}: #{e.message}"
    []
  end
end
