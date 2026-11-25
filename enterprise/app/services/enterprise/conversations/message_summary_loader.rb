module Enterprise::Conversations::MessageSummaryLoader
  private

  # Enterprise::Message#push_event_data adds the call of a voice call message
  def message_preloads
    super + [{ call: [:contact, :accepted_by_agent, { inbox: :channel, recording_attachment: :blob }] }]
  end
end
