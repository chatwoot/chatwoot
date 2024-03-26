# This concern is primarily targeted for business models dependent on external services
# The auth tokens we obtained on their behalf could expire or becomes invalid.
# We would be aware of it until we make the API call to the service and it throws error

# Example:
# when a user changes his/her password, the auth token they provided to chatwoot becomes invalid

# This module helps to capture the errors into a counter and when threshold is passed would mark
# the object to be reauthorized. We will also send an email to the owners alerting them of the error.

# In the UI, we will check for the reauthorization_required? status and prompt the reauthorization flow

module Reauthorizable
  extend ActiveSupport::Concern
  include ErrorTrackable

  included do
    setup_error_threshold(
      self::AUTHORIZATION_ERROR_THRESHOLD,
      :prompt_reauthorization!
    )
  end

  AUTHORIZATION_ERROR_THRESHOLD = 2

  # model attribute
  def reauthorization_required?
    threshold_breached?
  end

  # Performed automatically if error threshold is breached
  # could used to manually prompt reauthorization if auth scope changes
  def prompt_reauthorization!
    mailer = AdministratorNotifications::ChannelNotificationsMailer.with(account: account)

    case self.class.name
    when 'Integrations::Hook'
      process_integration_hook_reauthorization_emails(mailer)
    when 'Channel::FacebookPage'
      mailer.facebook_disconnect(inbox).deliver_later
    when 'Channel::Whatsapp'
      mailer.whatsapp_disconnect(inbox).deliver_later
    when 'Channel::Email'
      mailer.email_disconnect(inbox).deliver_later
    end
  end

  def process_integration_hook_reauthorization_emails(mailer)
    if slack?
      mailer.slack_disconnect.deliver_later
    elsif dialogflow?
      mailer.dialogflow_disconnect.deliver_later
    end
  end

  # call this after you successfully Reauthorized the object in UI
  def reauthorized!
    reset_error_count
  end
end
