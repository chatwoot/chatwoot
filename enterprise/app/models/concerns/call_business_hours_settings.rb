# Per-inbox "Apply business hours to calls" settings kept in provider_config. Off by default,
# so voice inboxes that already have business hours for chat keep ringing as before.
# A plain module (no ActiveSupport::Concern) so it can be included into a prepended Enterprise module.
module Concerns::CallBusinessHoursSettings
  def business_hours_calls_enabled?
    provider_config['business_hours_calls_enabled'] == true
  end

  def out_of_hours_call_message
    provider_config['out_of_hours_call_message']
  end

  # Twilio only: after the out-of-hours message the caller can leave a voicemail
  def voicemail_enabled?
    provider_config['voicemail_enabled'] == true
  end
end
