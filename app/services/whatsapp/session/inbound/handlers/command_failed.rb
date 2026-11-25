# A fire-and-forget command could not be executed. A send has something to show for it:
# its message is marked failed so the agent sees it did not go out. A teardown the
# connector never attempted is sent again (see Whatsapp::Session::TeardownRetry).
class Whatsapp::Session::Inbound::Handlers::CommandFailed < Whatsapp::Session::Inbound::Handlers::Base
  def perform
    Rails.logger.warn(
      "[WHATSAPP SESSION] command #{payload.command_type} failed on inbox #{inbox.id}: #{payload.error&.code}"
    )
    return teardown_failed if Whatsapp::Session::TeardownRetry.teardown?(payload)
    # Nothing here sends call commands any more; a failure of one sent before that names no
    # message and has nothing to mark.
    return :ignored if payload.command_type.to_s.start_with?('call.')

    message = pending_message
    return :ignored if message.nil?

    inbound::StatusTransition.apply(message, 'failed', error: payload.error) ? :handled : :ignored
  end

  private

  # The connector is the only provider that answers a teardown this way, and the only one
  # the retry knows how to reach.
  def teardown_failed
    return :ignored unless channel.provider == 'native'

    Whatsapp::Session::TeardownRetry.consider(event) ? :handled : :ignored
  end

  # The send reserved its WhatsApp id before dispatching, so the failed command points
  # at a message that may not carry that id as source_id yet.
  def pending_message
    return if payload.message_id.blank?

    find_message(payload.message_id) || inbox.messages.where(
      "(content_attributes#>>'{}')::jsonb->>'pending_source_id' = ?", payload.message_id
    ).first
  end
end
