module Voice
  class ConferenceStatusUpdateService
    pattr_initialize [:conversation!, :event!, :call_sid!, :conference_sid, :participant_sid, :participant_label]

    def process
      # Use the ConferenceManagerService to handle all conference events
      Voice::ConferenceManagerService.new(
        conversation: conversation,
        event: event,
        call_sid: call_sid,
        conference_sid: conference_sid,
        participant_sid: participant_sid,
        participant_label: participant_label
      ).process
    end
  end
end