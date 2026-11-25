# The single place that decides whether a delivery receipt may move a message forward.
#
# The legacy layer had this rule twice (messages.update and message-receipt.update) and
# they had already drifted apart. Receipts can arrive out of order, so the rule is
# monotonic: a message never goes back to a weaker status, and `read` is terminal.
module Whatsapp::Session::Inbound::StatusTransition
  # `played` is a voice note being listened to, which Chatwoot has no column for and
  # which always implies read.
  RECEIPTS = { 'delivered' => 'delivered', 'read' => 'read', 'played' => 'read', 'failed' => 'failed' }.freeze
  RANK = { 'sent' => 0, 'delivered' => 1, 'read' => 2 }.freeze
  # No FAILURE moves a message out of these. A failure reported after the message was
  # delivered or read describes an earlier attempt, not the message coming undone:
  # either status is proof it arrived. A second failure has nothing left to say.
  #
  # The reverse is not symmetric, and that asymmetry is the point: a positive receipt
  # after a failure is proof the message arrived, and proof outranks a verdict. The
  # verdict may have been ours (a send we stopped waiting on, which says nothing about
  # what WhatsApp did with it) or the provider's about ONE attempt — and with a
  # caller-reserved id every attempt carries the same key, so a NACK on the first and a
  # delivery on the second describe the same message. Leaving it failed would keep
  # offering the agent a resend for a message the customer already has.
  TERMINAL = %w[delivered read failed].freeze

  module_function

  # Returns true when the message was updated.
  #
  # Checked and written under the row lock. Two receipts for the same message can be
  # processed at once, and reading the status outside the lock lets both pass the check
  # against the same old value: the slower `delivered` write then lands on top of `read`
  # and walks the message backwards, which is exactly what this rule exists to prevent.
  def apply(message, receipt_type, error: nil)
    status = RECEIPTS[receipt_type.to_s]
    return false if status.blank?

    message.with_lock do
      next false unless allowed?(message.status, status)

      message.update!(failure_attributes(status, error))
      true
    end
  end

  # The SEND side's failure writer, as opposed to `apply`, which records what the provider
  # told us. The difference is source_id: it is only ever written by the provider
  # confirming the message exists on WhatsApp — the send response, or the echo promoting a
  # reservation — so a send WE could not confirm has nothing to say about a message the
  # provider already confirmed, and saying it anyway invites the agent to resend a
  # duplicate. Read under the row lock, because the echo can land while the last attempt
  # is still unwinding.
  #
  # `apply` deliberately does NOT carry this rule: a provider-reported failure (a 463 NACK,
  # say) is about a message that did reach the server, and suppressing that would hide a
  # real delivery failure.
  def fail_send(message, reason)
    message.with_lock do
      next false if message.source_id.present?

      apply(message, 'failed', error: reason)
    end
  end

  def failure_attributes(status, error)
    return { status: :failed, external_error: error_message(error) } if status == 'failed'

    # Cleared, not just left behind: the dashboard decides between "resend" and "recreate"
    # by whether a failed message carries an external_error, so a stale one on a message
    # the receipt just confirmed would keep the resend button on a delivered message.
    { status: status, external_error: nil }
  end

  def allowed?(current, new_status)
    return false if current.in?(TERMINAL) && new_status == 'failed'
    return false if current == 'read'
    return true if new_status == 'failed'

    RANK.fetch(new_status, -1) > RANK.fetch(current, -1)
  end

  def error_message(error)
    return if error.blank?
    return error if error.is_a?(String)

    [error.message.presence, error.code.presence].compact.join(' ').presence
  end
end
