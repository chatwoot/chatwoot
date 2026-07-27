module Enterprise::Api::V2::Widget::ConfigsController
  private

  def ai_agent_config
    return unless ai_agent_active?

    assistant = inbox.captain_assistant
    {
      name: assistant.name,
      description: assistant.description,
      avatar_url: assistant.avatar_url,
      welcome_message: assistant.config['welcome_message'],
      handoff_message: assistant.config['handoff_message']
    }
  end
end
