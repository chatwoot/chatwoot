class Attachments::BackupFileJob < ApplicationJob
  queue_as :low
  ALLOW_BACKUP_TYPES = %w[image video audio file].freeze

  def perform(attachment_id)
    @attachment = ::Attachment.find(attachment_id)
    return if skipped?

    @attachment.update!(file: {
      io: downloaded_file,
      filename: downloaded_file.original_filename,
      content_type: downloaded_file.content_type
    })
  end

  private

  def skipped?
    return true if @attachment.file.attached?
    return true if ALLOW_BACKUP_TYPES.exclude?(@attachment.file_type)
    return @attachment.external_url.blank?
  end

  def downloaded_file
    @downloaded_file ||= Down::NetHttp.download(@attachment.external_url)
  end
end
