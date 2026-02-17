# frozen_string_literal: true

# Redis::SecureStorage provides encrypted storage for sensitive temporary data in Redis.
# Uses ActiveSupport::MessageEncryptor with AES-256-GCM for authenticated encryption.
#
# Example:
#   Redis::SecureStorage.set('session:token', { access_token: 'secret' }, 10.minutes)
#   data = Redis::SecureStorage.get('session:token')
#
module Redis::SecureStorage
  class << self
    # Store data in Redis with encryption
    # @param key [String] Redis key
    # @param data [Hash, String] Data to store (will be converted to JSON)
    # @param expiry [Integer, ActiveSupport::Duration] TTL in seconds
    def set(key, data, expiry)
      encrypted = encrypt(data)
      Alfred.setex(key, encrypted, expiry)
    end

    # Retrieve and decrypt data from Redis
    # @param key [String] Redis key
    # @return [Hash, nil] Decrypted data or nil if not found/invalid
    def get(key)
      encrypted = Alfred.get(key)
      return nil if encrypted.blank?

      decrypt(encrypted)
    rescue ActiveSupport::MessageEncryptor::InvalidMessage, JSON::ParserError
      nil
    end

    # Delete data from Redis
    # @param key [String] Redis key
    def delete(key)
      Alfred.delete(key)
    end

    private

    def encryptor
      @encryptor ||= ActiveSupport::MessageEncryptor.new(
        Rails.application.credentials.secret_key_base[0..31],
        cipher: 'aes-256-gcm'
      )
    end

    def encrypt(data)
      json_data = data.is_a?(String) ? data : data.to_json
      return json_data unless Chatwoot.encryption_configured?

      encryptor.encrypt_and_sign(json_data)
    end

    def decrypt(encrypted_data)
      return encrypted_data unless Chatwoot.encryption_configured?

      encryptor.decrypt_and_verify(encrypted_data)
    end
  end
end
