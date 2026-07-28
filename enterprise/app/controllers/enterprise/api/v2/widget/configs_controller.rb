module Enterprise::Api::V2::Widget::ConfigsController
  private

  def ai_agent_config
    return unless ai_agent_active?

    assistant = inbox.captain_assistant
    # push_event_data already falls back to the Captain logo when the assistant
    # has no uploaded avatar.
    assistant.push_event_data.slice(:name, :description, :avatar_url).merge(
      welcome_message: assistant.config['welcome_message'],
      handoff_message: assistant.config['handoff_message']
    )
  end
end
