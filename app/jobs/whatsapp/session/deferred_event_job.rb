# A connector event about a message that is not stored yet, tried again later.
#
# The connector delivers a session's events in order, so on that path a missing target
# used to mean one this inbox never had. History import broke that: a slice is queued as a
# job and written when an import slot frees up, so an edit, a revoke or a reaction that
# follows it on the stream can arrive while the message it is about is still waiting to be
# filed. Dropping it there keeps the text from before the edit, or loses the reaction, for
# good.
#
# The same bounded wait the webhook path gives the same problem (see
# Webhooks::WhatsappSessionEventsJob), and dropped at the end for the same reason: a target
# this inbox never stored is ordinary, not a failure.
class Whatsapp::Session::DeferredEventJob < ApplicationJob
  queue_as :low

  PENDING_WAIT = 1.minute

  retry_on Whatsapp::Session::Inbound::Locks::Busy, wait: 30.seconds, attempts: 20
  retry_on Whatsapp::Session::Errors::EventOutOfOrder, wait: :polynomially_longer, attempts: 5 do |job, error|
    Rails.logger.warn("[WHATSAPP SESSION] giving up on a deferred event for channel ##{job.arguments.first&.id}: #{error.message}")
  end

  # `frame` is the event as the connector published it, so the retry reads exactly what the
  # consumer read.
  def perform(channel, frame)
    # The channel is read as it is now, so the dispatcher's own check against a conversion
    # compares the new provider with itself. The frame still names the session it came
    # from, and an inbox that no longer holds it is not where this edit belongs.
    return unless channel.provider == 'native' && channel.provider_config&.dig('session_id') == frame['sid']

    event = Whatsapp::Session::Model::Event.from_frame(frame)
    return unless Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event) == :deferred
    # A slice still queued may be carrying the target, and it can wait for a slot longer than
    # the ladder below lasts: waited out without spending the ladder.
    return retry_job(wait: PENDING_WAIT) if Whatsapp::Session::HistoryImportJob.pending?(channel.inbox)

    raise Whatsapp::Session::Errors::EventOutOfOrder, "#{event.type} arrived before the message it refers to"
  end
end
