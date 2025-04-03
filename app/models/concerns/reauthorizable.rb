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

  AUTHORIZATION_ERROR_THRESHOLD = 2

  # model attribute
  def reauthorization_required?
    ::Redis::Alfred.get(reauthorization_required_key).present?
  end

  # model attribute
  def authorization_error_count
    ::Redis::Alfred.get(authorization_error_count_key).to_i
  end

  # action to be performed when we receive authorization errors
  # Implement in your exception handling logic for authorization errors
  def authorization_error!
    ::Redis::Alfred.incr(authorization_error_count_key)
    # we are giving precendence to the authorization error threshhold defined in the class
    # so that channels can override the default value
    prompt_reauthorization! if authorization_error_count >= self.class::AUTHORIZATION_ERROR_THRESHOLD
  end

  # Performed automatically if error threshold is breached
  # could used to manually prompt reauthorization if auth scope changes
  def prompt_reauthorization!
    ::Redis::Alfred.set(reauthorization_required_key, true)

    reauthorization_handlers[self.class.name]&.call(self)

    invalidate_inbox_cache unless instance_of?(::AutomationRule)
  end

  def process_integration_hook_reauthorization_emails
    if slack?
      AdministratorNotifications::IntegrationsNotificationMailer.with(account: account).slack_disconnect.deliver_later
    elsif dialogflow?
      AdministratorNotifications::IntegrationsNotificationMailer.with(account: account).dialogflow_disconnect.deliver_later
    end
  end

  def send_channel_reauthorization_email(disconnect_type)
    AdministratorNotifications::ChannelNotificationsMailer.with(account: account).public_send(disconnect_type, inbox).deliver_later
  end

  def handle_automation_rule_reauthorization
    update!(active: false)
    AdministratorNotifications::AccountNotificationMailer.with(account: account).automation_rule_disabled(self).deliver_later
  end

  # call this after you successfully Reauthorized the object in UI
  def reauthorized!
    ::Redis::Alfred.delete(authorization_error_count_key)
    ::Redis::Alfred.delete(reauthorization_required_key)

    invalidate_inbox_cache unless instance_of?(::AutomationRule)
  end

  private

  def reauthorization_handlers
    {
      'Integrations::Hook' => ->(obj) { obj.process_integration_hook_reauthorization_emails },
      'Channel::FacebookPage' => ->(obj) { obj.send_channel_reauthorization_email(:facebook_disconnect) },
      'Channel::Instagram' => ->(obj) { obj.send_channel_reauthorization_email(:instagram_disconnect) },
      'Channel::Whatsapp' => ->(obj) { obj.send_channel_reauthorization_email(:whatsapp_disconnect) },
      'Channel::Email' => ->(obj) { obj.send_channel_reauthorization_email(:email_disconnect) },
      'AutomationRule' => ->(obj) { obj.handle_automation_rule_reauthorization }
    }
  end

  def invalidate_inbox_cache
    inbox.update_account_cache if inbox.present?
  end

  def authorization_error_count_key
    format(::Redis::Alfred::AUTHORIZATION_ERROR_COUNT, obj_type: self.class.table_name.singularize, obj_id: id)
  end

  def reauthorization_required_key
    format(::Redis::Alfred::REAUTHORIZATION_REQUIRED, obj_type: self.class.table_name.singularize, obj_id: id)
  end
end
