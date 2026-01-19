class AdministratorNotifications::IntegrationsNotificationMailer < AdministratorNotifications::BaseMailer
  def slack_disconnect
    subject = 'Your Slack integration has expired'
    action_url = settings_url('integrations/slack')
    send_notification(subject, action_url: action_url)
  end

  def dialogflow_disconnect
    subject = 'Your Dialogflow integration was disconnected'
    send_notification(subject)
  end

  def openai_disconnect
    subject = 'Your OpenAI integration needs attention'
    action_url = settings_url('integrations/openai')
    send_notification(subject, action_url: action_url)
  end
end
