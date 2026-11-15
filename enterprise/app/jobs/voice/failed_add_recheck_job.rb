# Decides again an agent's failed connection that was set aside while another of their
# connections was on its way in, once that connection's time to join is up: it has joined,
# and the failure is left alone, or it has not, and the failure takes effect.
class Voice::FailedAddRecheckJob < ApplicationJob
  queue_as :critical

  def perform(call_id, participant_label, participant_call_sid)
    call = Call.find_by(id: call_id)
    return if call.blank? || call.terminal?

    Voice::Conference::Manager.new(call: call, event: 'leave', participant_label: participant_label,
                                   participant_call_sid: participant_call_sid, leave_reason: 'participant_add_failed').process
  end
end
