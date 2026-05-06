module Voice::CallErrors
  # Meta WhatsApp Cloud Calling error code returned when the contact has not
  # granted call permission yet. See `initiate_call` in
  # Enterprise::Whatsapp::Providers::WhatsappCloudService.
  NO_CALL_PERMISSION_CODE = 138_006

  class NoCallPermission < StandardError; end
  class CallFailed < StandardError; end
  class NotRinging < StandardError; end
  class AlreadyAccepted < StandardError; end
end
