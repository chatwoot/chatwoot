class AdministratorNotifications::IntegrationsNotificationMailer < AdministratorNotifications::BaseMailer
  def dialogflow_disconnect
    subject = 'Your Dialogflow integration was disconnected'
    send_notification(subject)
  end

end
