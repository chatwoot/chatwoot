# The number's calling settings at Meta: calling itself, callback requests, and call hours. Part of
# Enterprise::Whatsapp::Providers::WhatsappCloudService, whose request helpers it uses.
module Enterprise::Whatsapp::Providers::WhatsappCloudCallSettings
  # Bounds connecting, sending, and reading each settings request, so a call hours sync finishes
  # inside its lock (Whatsapp::SyncCallHoursJob::LOCK_TIMEOUT)
  SETTINGS_REQUEST_TIMEOUT_SECONDS = 15

  # Sets WABA calling status ('ENABLED'/'DISABLED')
  def update_calling_status(status)
    update_calling_settings(status: status)
  end

  # Sets whether WhatsApp offers a caller nobody answered to request a callback ('ENABLED'/'DISABLED')
  def update_callback_permission_status(status)
    update_calling_settings(callback_permission_status: status)
  end

  # Replaces the hours WhatsApp puts calls through, holidays included
  def update_call_hours(call_hours)
    update_calling_settings(call_hours: call_hours)
  end

  # The number's calling settings as Meta holds them, or raises with Meta's message
  def calling_settings
    response = HTTParty.get(
      "#{calls_phone_id_path}/settings", headers: api_headers, timeout: SETTINGS_REQUEST_TIMEOUT_SECONDS
    )
    return response.parsed_response if response.success?

    Rails.logger.error "[WHATSAPP CALL] calling_settings failed: status=#{response.code} body=#{response.body}"
    raise meta_error_message(response_error(response), 'Failed to read calling settings')
  end

  private

  # Updates the given calling settings only. Returns true, or raises with Meta's user-facing
  # message on failure so the caller can surface it.
  def update_calling_settings(settings)
    response = HTTParty.post(
      "#{calls_phone_id_path}/settings",
      headers: api_headers,
      body: { calling: settings }.to_json,
      timeout: SETTINGS_REQUEST_TIMEOUT_SECONDS
    )
    return true if response.success?

    Rails.logger.error "[WHATSAPP CALL] update_calling_settings failed: keys=#{settings.keys.join(',')} status=#{response.code} body=#{response.body}"
    raise meta_error_message(response_error(response), 'Failed to update calling settings')
  end

  def response_error(response)
    parsed = response.parsed_response.is_a?(Hash) ? response.parsed_response : {}
    parsed['error'].is_a?(Hash) ? parsed['error'] : {}
  end
end
