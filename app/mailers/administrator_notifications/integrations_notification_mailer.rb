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

  def calendly_disconnect
    subject = 'Your Calendly integration needs to be reconnected'
    action_url = settings_url('integrations/calendly')
    send_notification(subject, action_url: action_url)
  end
end
