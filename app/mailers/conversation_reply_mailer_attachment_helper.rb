# Handles attachment processing for ConversationReplyMailer flows.
module ConversationReplyMailerAttachmentHelper
  private

  def process_attachments_as_files_for_email_reply
    # Attachment processing for direct email replies (when replying to a single message)
    #
    # How attachments are handled:
    # 1. Total file size (<20MB): Added directly to the email as proper attachments
    # 2. Total file size (>20MB): Added to @large_attachments to be displayed as links in the email

    @options[:attachments] = []
    @large_attachments = []
    current_total_size = 0

    @message.attachments.each do |attachment|
      current_total_size = handle_attachment_inline(current_total_size, attachment)
    end
  end

  def read_blob_content(blob)
    buffer = +''
    blob.open do |file|
      while (chunk = file.read(64.kilobytes))
        buffer << chunk
      end
    end
    buffer
  end

  def handle_attachment_inline(current_total_size, attachment)
    blob = attachment.file.blob
    return current_total_size if blob.blank?

    file_size = blob.byte_size
    attachment_name = attachment.file.filename.to_s

    if current_total_size + file_size <= 20.megabytes
      content = read_blob_content(blob)
      mail.attachments[attachment_name] = {
        mime_type: attachment.file.content_type || 'application/octet-stream',
        content: content
      }
      @options[:attachments] << { name: attachment_name }
      current_total_size + file_size
    else
      @large_attachments << attachment
      current_total_size
    end
  end
end
