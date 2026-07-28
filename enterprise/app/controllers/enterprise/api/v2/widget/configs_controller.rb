module Enterprise::Api::V2::Widget::ConfigsController
  private

  def ai_agent_config
    return unless ai_agent_active?

    assistant = inbox.captain_assistant
    {
      name: assistant.name,
      description: assistant.description,
      # Only a genuinely uploaded avatar is sent. The default Captain logo is
      # Chatwoot's own mark, so the widget renders a themed glyph instead and
      # stays white-label on the customer's site.
      avatar_url: assistant.avatar_url.presence,
      welcome_message: assistant.config['welcome_message'],
      handoff_message: assistant.config['handoff_message']
    }
  end
end
