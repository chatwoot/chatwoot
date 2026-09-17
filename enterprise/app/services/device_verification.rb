module DeviceVerification
  def self.enabled?
    ChatwootApp.chatwoot_cloud? &&
      ActiveModel::Type::Boolean.new.cast(GlobalConfig.get_value('DEVICE_VERIFICATION_ENABLED')).present?
  end

  # The code must never appear in serialized job arguments: Sidekiq's error
  # handler logs the full payload on failure regardless of log_arguments.
  def self.encrypt_code(code)
    code_encryptor.encrypt_and_sign(code)
  end

  def self.decrypt_code(ciphertext)
    code_encryptor.decrypt_and_verify(ciphertext)
  end

  def self.code_encryptor
    key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base)
                                     .generate_key('device_verification_code', 32)
    ActiveSupport::MessageEncryptor.new(key)
  end
  private_class_method :code_encryptor
end
