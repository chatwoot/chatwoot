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
      Redis::Alfred.setex(key, encrypted, expiry)
    end

    # Retrieve and decrypt data from Redis
    # @param key [String] Redis key
    # @return [Hash, nil] Decrypted data or nil if not found/invalid
    def get(key)
      encrypted = Redis::Alfred.get(key)
      return nil if encrypted.blank?

      decrypt(encrypted)
    rescue ActiveSupport::MessageEncryptor::InvalidMessage, JSON::ParserError
      nil
    end

    # Delete data from Redis
    # @param key [String] Redis key
    def delete(key)
      Redis::Alfred.delete(key)
    end

    private

    def encryptor
      @encryptor ||= begin
        # Derive a proper 32-byte key from secret_key_base
        key_generator = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base)
        key = key_generator.generate_key('redis_secure_storage', 32)
        ActiveSupport::MessageEncryptor.new(key, cipher: 'aes-256-gcm')
      end
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
