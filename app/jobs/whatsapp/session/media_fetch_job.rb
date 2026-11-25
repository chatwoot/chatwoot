# Downloads the bytes of an inbound media message and attaches them.
#
# Separate from the message row on purpose: the connector's consumer thread keeps a
# session's events in order, and a multi-megabyte download must not hold it. The
# message is created first and gains its attachment seconds later.
class Whatsapp::Session::MediaFetchJob < ApplicationJob
  queue_as :medium

  retry_on Down::Error, wait: :polynomially_longer, attempts: 3
  retry_on Whatsapp::Session::Errors::ProviderUnavailable, wait: :polynomially_longer, attempts: 3

  # `content` is a serialized Model::Content::Media, `chat` the serialized Address the
  # event carried.
  def perform(message, content, chat = nil)
    return if message.attachments.any?
    return Whatsapp::Session::HistoryMedia.as_history(message) { perform(message, content, chat) } if imported?(message)

    channel = message.inbox.channel
    media = Whatsapp::Session::Model::Content.from_h(content)
    refusal = conversion_refusal(channel, media)
    return give_up(message, refusal) if refusal

    payload = channel.session_backend.download_media(download_command(message, media, chat))
    # Re-read under lock, after the download: a deletion that landed while this job was
    # queued or running destroyed the attachments, and attaching now would put the
    # supposedly deleted media back into storage and back on the API.
    message.with_lock do
      next if message.reload.deleted? || message.attachments.any?

      attach(message, media, payload)
      # `MESSAGE_UPDATED` only reaches the open thread, so the conversation card in the
      # list keeps its "no content" preview for a media-only message until something else
      # touches that conversation.
      Whatsapp::Session::Inbound::ChatList.refresh(message.conversation)
    end
  rescue Whatsapp::Session::Errors::MediaUnavailable, Whatsapp::Session::Errors::NotSupported,
         Whatsapp::Session::Errors::MediaTooLarge => e
    # The provider will not hand over these bytes, now or on a retry: it no longer has
    # them, it cannot serve them, or the file is past its size cap.
    give_up(message, e.message)
  end

  private

  def imported?(message)
    message.content_attributes&.dig('imported').present? && !Import::SilentWrite.on?
  end

  # One question in two halves, both about a queue entry that outlived a conversion: can
  # the inbox this message belongs to still fetch these bytes?
  #
  # Asked here rather than caught from the backend, so that a native inbox which is simply
  # misconfigured still fails loudly instead of quietly marking its media unsupported.
  #
  # The second half is the one that survives being in the family: a connector blob and a
  # Uazapi message id mean nothing to anyone but the provider that issued them, and the
  # conversion has already disconnected the one that did.
  #
  # It only has anything to say about a ref that exists. A fetch for a message whose file
  # never came carries none, and asks the provider by message id alone -- which is the
  # same thing the refresh behind a lapsed ref does, and is answered the same way when the
  # provider does not know the message.
  def conversion_refusal(channel, media)
    return "inbox ##{channel.inbox.id} left the session layer" unless channel.session_provider?
    return if media.ref.nil?
    return "ref was issued by a provider other than #{channel.provider}" unless media.ref.served_by?(channel.provider)

    nil
  end

  # The agent needs to see that the attachment is not coming rather than a bubble that
  # loads forever. Under lock and off a reloaded row: `is_unsupported` is a
  # content_attributes flag, and a revoke that landed during the download would be
  # rewritten away by this.
  #
  # An imported file stops waiting here too, or every later delivery of the same message
  # would ask again for bytes the provider has just said it will not hand over. The header
  # of a readable history card is the exception to the flag: the card keeps its text and
  # buttons, only without the picture.
  def give_up(message, reason)
    Rails.logger.warn("[WHATSAPP SESSION] media unavailable for message #{message.id}: #{reason}")
    return spare_card(message) if message.content_attributes&.dig('imported').present? && Whatsapp::Session::HistoryMedia.readable_card?(message)

    # The same file can be asked for twice at once (the drain and the button), and the other
    # ask may have attached it by now: marking it unsupported would hide the file it got.
    message.with_lock do
      next if message.attachments.any?

      message.update!(is_unsupported: true)
    end
    return if message.content_attributes&.dig(history_media).blank?

    message.with_lock { message.update!(content_attributes: message.content_attributes.except(history_media)) }
  end

  # A history card whose header is gone keeps its text and buttons, so it is not marked
  # unsupported; its own mark, which `given_up?` reads in place of that flag, keeps a later
  # delivery from asking again.
  def spare_card(message)
    message.with_lock do
      next if message.attachments.any?

      message.update!(content_attributes: message.content_attributes.except(history_media).merge('media_unavailable' => true))
    end
  end

  def history_media = Whatsapp::Session::Inbound::MessageAttributes::HISTORY_MEDIA

  # The ref alone is not enough to ask for a second time: a blob the provider has already
  # dropped is fetched again from the message it came from, so the command carries the
  # message the ref belongs to as well as the ref itself.
  #
  # The chat is the one the event carried, never one rebuilt from the contact.
  # ContactResolver stores the sender's LID as the contact identifier whenever it has
  # one, so rebuilding addresses the refresh to a chat the message does not live in, and
  # the provider answers that it cannot find the message.
  def download_command(message, media, chat)
    Whatsapp::Session::Model::Commands::MessageDownloadMedia.new(
      chat: chat.presence && Whatsapp::Session::Model::Address.from_h(chat),
      message_id: message.source_id, ref: media.ref
    )
  end

  def attach(message, media, payload)
    Whatsapp::Session::Inbound::MediaAttachment.build(message, media, payload)
    # An imported file that was only waiting for its reference is a file again, and so is
    # one another ask had just given up on: two asks for the same file can overlap (the
    # drain and the button), and the one that lost must not leave the file hidden.
    attributes = message.content_attributes || {}
    if attributes[history_media].present? || attributes['imported'].present?
      message.content_attributes = attributes.except('is_unsupported', history_media, 'media_unavailable')
    end
    # Adding an attachment changes no column on the message, and
    # `Message#dispatch_update_event` returns early on an empty `previous_changes`, so
    # nothing would tell the open dashboards that the bubble finally has its file: the
    # agent would keep seeing the empty bubble until a reload. Stamping `updated_at` in
    # the same save is what makes the row dirty enough to broadcast, once, with the
    # attachment already committed.
    message.updated_at = Time.current
    message.save!
  end
end
