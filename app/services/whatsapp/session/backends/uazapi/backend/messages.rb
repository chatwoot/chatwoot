# The messaging half of the Uazapi backend: what a message becomes on the way out, and
# how the bytes of one come back.
#
# Split from the backend for the same reason the facade splits its group half: the class
# was translating two different APIs at once.
module Whatsapp::Session::Backends::Uazapi::Backend::Messages
  # WhatsApp media kind -> the `/send/media` type. A voice note is its own type there.
  MEDIA_TYPES = { 'image' => 'image', 'video' => 'video', 'audio' => 'audio', 'document' => 'document',
                  'sticker' => 'sticker' }.freeze

  def send_message(command)
    content = command.content
    case content&.wire_type
    when 'text' then send_text(command, content)
    when 'media' then send_media(command, content)
    else raise Whatsapp::Session::Errors::InvalidPayload, "uazapi cannot send #{content&.wire_type.inspect}"
    end
  end

  def edit_message(command)
    # The provider answers with a NEW message id that points at the original through its
    # `edited` field, so the id is deliberately not read back here: writing it onto the
    # row would rename the message the conversation already knows and orphan every
    # receipt, reaction and revoke that still names the original.
    client.post('/message/edit', { id: command.target_id, text: text_of(command.content) })
    model::SendResult.new(message_id: command.target_id)
  end

  def revoke_message(command)
    client.post('/message/delete', { id: command.target_id })
    true
  end

  def react_message(command)
    result = client.post('/message/react', { number: number(command.to), id: command.target_id, text: command.emoji.to_s })
    send_result(result, command)
  end

  def mark_read(command)
    client.post('/message/markread', { id: Array(command.message_ids) })
    nil
  end

  # Two round trips, because the URL a media message carries is the encrypted blob on
  # WhatsApp's own CDN: it cannot be fetched without the message's media key, which only
  # the provider has. `/message/download` is what turns it into bytes we can read.
  #
  # NOTE: the provider transcodes on the way out. A voice note recorded as
  # `audio/ogg; codecs=opus` came back as `audio/mpeg`, so what lands on the attachment is
  # the converted file, not the original.
  def download_media(command)
    ref = command.ref || model::MediaRef.new(kind: 'uazapi_message', id: command.message_id)
    return fetch(ref.url, mime: ref.mime) if ref.kind == 'url' && ref.fetchable?

    link = decrypted(ref.id.presence || command.message_id)
    fetch(link['fileURL'], mime: link['mimetype'].presence || ref.mime)
  end

  private

  # A 404 here is the media, not the instance. The provider keeps a decrypted copy for a
  # while and answers 404 once it is gone, which the client maps to `session_not_found`
  # like every other 404 it sees. Left as that it is a retryable provider outage, so the
  # fetch job spends its whole ladder on a file that will never come back and then dies
  # without marking the bubble: the agent is left with an empty attachment and no reason.
  def decrypted(message_id)
    link = client.post('/message/download', { id: message_id, return_link: true }).to_h
    raise Whatsapp::Session::Errors::MediaUnavailable, 'uazapi returned no file url' if link['fileURL'].blank?

    link
  rescue Whatsapp::Session::Errors::SessionNotFound => e
    raise Whatsapp::Session::Errors::MediaUnavailable, e.message
  end

  # `track_id` is how an echo is recognized: this provider assigns its own message ids, so
  # the reserved id travels here and comes back on the webhook. Chatwoot's own sends are
  # excluded from the webhook, which makes this the fallback for the case where the
  # exclusion does not apply (another device replaying our text).
  def send_text(command, content)
    send_result(client.post('/send/text', base_body(command).merge(text: content.body.to_s)), command)
  end

  def send_media(command, content)
    body = base_body(command).merge(
      type: media_type(content), file: media_source(content), text: content.caption.presence, docName: content.filename.presence
    )
    send_result(client.post('/send/media', body, timeout: Whatsapp::Session::Backends::Uazapi::Client::UPLOAD_TIMEOUT), command)
  end

  def base_body(command)
    { number: number(command.to), replyid: command.quoted&.id, mentions: mentions(command), track_id: command.client_ref }
  end

  def mentions(command)
    Array(command.mentions).map { |address| number(address) }.presence
  end

  # A voice note is a type of its own on WhatsApp, and the file is what tells the two
  # apart: `audio` renders as a music file, `ptt` as the recorded-voice bubble.
  def media_type(content)
    return 'ptt' if content.kind == 'audio' && content.voice_note

    MEDIA_TYPES.fetch(content.kind, 'document')
  end

  # A URL the provider fetches itself, which is the whole point of not putting bytes on
  # the wire. There is nothing else to offer: the ref of an outbound attachment is always
  # a URL this app serves.
  def media_source(content)
    url = content.ref&.url
    raise Whatsapp::Session::Errors::InvalidPayload, 'outbound media has no url' if url.blank?

    url
  end

  def send_result(result, command)
    result = result.to_h
    model::SendResult.new(
      message_id: result['messageid'], timestamp: result['messageTimestamp'],
      client_ref: result['track_id'].presence || command.try(:client_ref)
    )
  end

  def text_of(content)
    content&.wire_type == 'text' ? content.body.to_s : content.try(:caption).to_s
  end
end
