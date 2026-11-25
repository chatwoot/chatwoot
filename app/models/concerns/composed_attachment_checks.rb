# What an attachment is refused for when we compose the message it travels in and are about to
# send it. Off by default on purpose: only those paths turn `refuse_empty_file` on, because a
# refusal on an ingested attachment raises inside the provider webhook and loses the whole message
# instead of storing an odd one. The flag lives in memory only, so reloading a row stored before a
# check existed never refuses it later.
module ComposedAttachmentChecks
  extend ActiveSupport::Concern

  included do
    attr_accessor :refuse_empty_file

    validate :file_is_not_empty, if: :refuse_empty_file
    validate :video_note_goes_alone, if: :refuse_empty_file
  end

  private

  # Separate from `acceptable_file`, which runs only on a web widget inbox: which *types* an inbox
  # accepts is a per-channel policy, while a file with no bytes is useless on every channel.
  def file_is_not_empty
    return unless file.attached? && file.byte_size.to_i.zero?

    errors.add(:file, 'is empty')
  end

  # Refused when the message is stored, so the caller hears a 422 instead of seeing the message
  # turn red later. The circle has nowhere to show a caption, and the connector refuses one. And
  # the native channel sends one file per message, the first: a note behind another file would
  # never leave. Only where the connector is the one sending: an API inbox records a note that went
  # out elsewhere, in whatever shape it went.
  def video_note_goes_alone
    return unless video_note? && sent_by_the_connector?

    errors.add(:base, I18n.t('errors.attachments.video_note.with_text')) if text_alongside?
    errors.add(:base, I18n.t('errors.attachments.video_note.not_alone')) if message.attachments.size > 1
  end

  # Not a message that arrives already carrying its WhatsApp id: the send job skips that one as
  # sent elsewhere, so nothing reaches the connector.
  def sent_by_the_connector?
    channel = message&.inbox&.channel
    channel.is_a?(Channel::Whatsapp) && channel.provider == 'native' && message.source_id.blank?
  end

  # Any text at all, even a blank one the dashboard would still read as a body and draw a rectangle
  # for, and the caption a survey writes even when the content is empty.
  def text_alongside?
    !message.content.to_s.empty? || message.outgoing_content.present?
  end
end
