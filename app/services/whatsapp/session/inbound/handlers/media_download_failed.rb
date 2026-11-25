# The provider could not hand over the media of a message it already delivered.
#
# Usually that is the end of it and the message is flagged, so the agent knows the
# attachment is gone rather than still loading. The exception is a file WhatsApp has
# dropped off its CDN while the sender's phone may still hold it: the provider says so on
# the event, and the answer is to ask for the bytes rather than to give up on them.
class Whatsapp::Session::Inbound::Handlers::MediaDownloadFailed < Whatsapp::Session::Inbound::Handlers::Base
  def perform
    message = find_message(payload.message_id)
    return :ignored if message.nil?
    return :ignored if message.attachments.any?

    return ask_again(message) if worth_asking_for?(message)

    # `is_unsupported` lives in the content_attributes JSON, so writing it off the
    # instance loaded before a revoke landed would rewrite the whole hash and undelete
    # the message.
    message.update_under_lock!(is_unsupported: true)
    Rails.logger.warn("[WHATSAPP SESSION] media download failed for #{payload.message_id}: #{payload.reason}")
    :handled
  end

  private

  # Both halves are the provider's answer and neither is enough alone: the flag says the
  # bytes may still be reachable, and the descriptor the writer kept is what a fetch
  # needs to attach them once they arrive. A message that carries no descriptor was never
  # published as one waiting for its file, so there is nothing here to ask for.
  def worth_asking_for?(message)
    payload.recoverable && message.content_attributes['pending_media'].present?
  end

  # Nothing is flagged. The bubble stays as it is while the fetch runs, and the job marks
  # it unsupported itself if the provider turns out not to reach the bytes either, which
  # is the same end this method is standing in front of.
  #
  # The chat is the one the event carried, for the same reason MediaFetchJob takes it
  # from the message event: a chat rebuilt from the contact addresses the fetch to a chat
  # the message does not live in.
  #
  # A message of an imported history is asked for through the inbox's drain instead, which
  # holds it to the automatic-fetch switch and window like every other history file.
  def ask_again(message)
    if message.content_attributes['imported'].present?
      wait_for_drain(message)
    else
      Whatsapp::Session::MediaFetchJob.perform_later(message, message.content_attributes['pending_media'], payload.chat&.to_h)
    end
    Rails.logger.info(
      "[WHATSAPP SESSION] media for #{payload.message_id} is #{payload.reason}, asking #{channel.provider} again"
    )
    :handled
  end

  # A placeholder of an imported message recovered live keeps its imported flag but not the
  # history mark the drain looks for, which is written at import time; it gets it here,
  # with the chat this event named, as history like every other write to that message.
  # Marked unsupported too, unless it is a card that reads without its file: with no
  # content and no attachment the dashboard would not render it, button included, while
  # it waits.
  def wait_for_drain(message)
    Whatsapp::Session::HistoryMedia.as_history(message) do
      message.with_lock do
        # A download may have attached the file, or the agent deleted the message, since
        # `perform` looked.
        next if Whatsapp::Session::HistoryMedia.settled?(message)

        message.update!(content_attributes: message.content_attributes.merge(
          'is_unsupported' => (true unless Whatsapp::Session::HistoryMedia.readable_card?(message)),
          Whatsapp::Session::Inbound::MessageAttributes::HISTORY_MEDIA => true, 'pending_chat' => payload.chat&.to_h
        ).compact)
      end
    end
    Whatsapp::Session::HistoryMedia.track(message)
  end
end
