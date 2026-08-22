module InboxBotStatus
  extend ActiveSupport::Concern

  def active_bot?
    captain_active?
  end

  def external_bot_active?
    dialogflow_active?
  end

  # Usage-based gating (upstream checks remaining Captain response credits)
  # was part of the removed enterprise edition; a connected assistant is
  # enough to treat the inbox as bot-handled in this build.
  def captain_active?
    captain_assistant.present?
  end

  private

  def dialogflow_active?
    hooks.exists?(app_id: %w[dialogflow], status: 'enabled')
  end
end
