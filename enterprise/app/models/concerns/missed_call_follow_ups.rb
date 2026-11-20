module Concerns::MissedCallFollowUps
  extend ActiveSupport::Concern

  included do
    # On create too: a call whose end arrived before its start is created and ended in one transaction
    after_commit :notify_missed_call, on: %i[create update], if: :missed_just_now?
    after_commit :send_whatsapp_missed_call_message, on: %i[create update], if: :whatsapp_missed_just_now?
  end

  private

  # Only a call that rang phones has a missed-call notice: the agents rung were recorded
  # as its ring started
  def missed_just_now?
    saved_change_to_status? && ring_state.key?('ring_recipient_ids') && ring_state['rings_phones'] != false && missed?
  end

  def notify_missed_call
    Voice::MissedCallNotificationJob.perform_later(id)
  end

  def whatsapp_missed_just_now?
    whatsapp? && saved_change_to_status? && missed?
  end

  def send_whatsapp_missed_call_message
    Whatsapp::MissedCallMessageJob.perform_later(id)
  end
end
