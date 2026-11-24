module Enterprise::Whatsapp::Providers::WhatsappCloudCallSettings
  SETTINGS_REQUEST_TIMEOUT_SECONDS = 15

  # Sets WABA calling status ('ENABLED'/'DISABLED')
  def update_calling_status(status)
    update_calling_settings(status: status)
  end

  def update_call_hours(call_hours)
    update_calling_settings(call_hours: call_hours)
  end

  # 'ENABLED' makes WhatsApp ask callers whether the business may call them back
  def update_callback_permission_status(status)
    update_calling_settings(callback_permission_status: status)
  end

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
