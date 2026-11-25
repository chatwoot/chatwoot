# The contact (or the connected phone) edited a message that is already stored.
class Whatsapp::Session::Inbound::Handlers::MessageEdited < Whatsapp::Session::Inbound::Handlers::Base
  def perform
    target = find_message(payload.message_id)
    # Not stored yet, as far as this transport can tell. On an ordered one it never was.
    return :deferred if target.nil?
    return :ignored if revoked?(target)

    content = edited_content
    # nil is a content type this layer cannot render as text; an empty string is a real
    # edit that removed the caption, and dropping it would leave the old one on screen.
    return :ignored if content.nil?
    return :ignored unless apply(target, content)

    inbound::ChatList.refresh(target.conversation)
    :handled
  end

  private

  # The message was deleted for everyone before this edit was applied. Editing it now
  # writes the edited text back onto a bubble the UI shows as deleted, which on a
  # delete-for-everyone also means restoring text WhatsApp has already taken off the
  # contact's phone. Nobody edits a message they have deleted, so this only ever happens
  # when the two arrive out of order.
  def revoked?(target)
    target.deleted? || target.deleted_by_contact
  end

  # Both the read and the write happen under the row lock: `is_edited`,
  # `previous_content` and `edited_at` live in the content_attributes JSON, so an edit
  # applied off an instance loaded before a concurrent revoke would serialize the
  # pre-revoke hash and bring a deleted message back, and the "what did it say before"
  # read has to see the same row it is about to write.
  #
  # False when this edit is older than the one already stored, which is what keeps two
  # edits of the same message from depending on which job ran last. The comparison is on
  # the provider's own clock rather than on arrival, since arrival is the thing that is
  # out of order; ties pass, because equal timestamps carry no order to respect.
  def apply(target, content)
    target.with_lock do
      next false if stale?(target)

      # The first edit is what the reader wants to compare against, so a second edit
      # does not overwrite the original.
      previous = target.is_edited ? target.previous_content : target.content
      target.content_attributes = target.content_attributes.except('is_unsupported') if placeholder?(target)
      target.update!(content: content, is_edited: true, previous_content: previous, edited_at: payload.timestamp)
      true
    end
  end

  def stale?(target)
    payload.timestamp.present? && target.edited_at.present? && payload.timestamp < target.edited_at
  end

  # An edit is the first readable body a placeholder's row has had, so that row is no
  # longer a message nothing could read: leaving the flag on renders the edit as the
  # unsupported bubble, which shows none of it.
  #
  # The recovery marker stays, though, and the two say different things now: the row has a
  # body and is still missing everything the message carried around it. The delayed
  # recovery reads that and contributes the rest without touching the body an edit of it
  # already settled.
  #
  # Only a placeholder, though. `is_unsupported` also marks media that never arrived, and
  # a new caption is no answer to bytes that are not coming.
  def placeholder?(target)
    target.content_attributes['unsupported_reason'].present?
  end

  # By wire type, not by class: a class captured before a reload stops matching and the
  # edit is dropped without a word.
  def edited_content
    case payload.content&.wire_type
    when 'text' then payload.content.body.to_s
    when 'media' then payload.content.caption.to_s
    when 'rich' then payload.content.preview_text.to_s
    end
  end
end
