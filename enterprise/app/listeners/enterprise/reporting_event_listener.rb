module Enterprise::ReportingEventListener
  def captain_conversation_handed_off(event)
    conversation_captain_inference_handoff(event) if event.data[:source] == 'inference'
  end
end
