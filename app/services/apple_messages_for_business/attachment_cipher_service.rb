class AppleMessagesForBusiness::AttachmentCipherService
  AES_256_CTR = 'AES-256-CTR'.freeze
  ZERO_IV = "\x00" * 16

  class << self
    def encrypt(data)
      # Generate a random 32-byte key for AES-256-CTR
      key = SecureRandom.random_bytes(32)

      # Use zero IV as per Apple specification
      iv = ZERO_IV

      # Create cipher
      cipher = OpenSSL::Cipher.new(AES_256_CTR)
      cipher.encrypt
      cipher.key = key
      cipher.iv = iv

      # Encrypt the data
      encrypted_data = cipher.update(data) + cipher.final

      # Return encrypted data and hex-encoded key with 00 prefix (as per Apple MSP spec)
      hex_key = "00" + key.unpack1('H*')
      [encrypted_data, hex_key]
    end

    def decrypt(encrypted_data, key_hex)
      Rails.logger.info "[AMB Cipher] Starting decryption. Encrypted data size: #{encrypted_data.bytesize}"
      Rails.logger.info "[AMB Cipher] Encrypted data (first 50 bytes): #{encrypted_data[0..49].inspect}"
      # Decode the hex key (remove 00 prefix as per Apple MSP spec)
      hex_without_prefix = key_hex.start_with?('00') ? key_hex[2..-1] : key_hex
      key = [hex_without_prefix].pack('H*')

      # Use zero IV as per Apple specification
      iv = ZERO_IV

      # Create cipher
      cipher = OpenSSL::Cipher.new(AES_256_CTR)
      cipher.decrypt
      cipher.key = key
      cipher.iv = iv

      # Decrypt the data
      decrypted_data = cipher.update(encrypted_data) + cipher.final
      Rails.logger.info "[AMB Cipher] Decryption complete. Decrypted data size: #{decrypted_data.bytesize}"
      Rails.logger.info "[AMB Cipher] Decrypted data (first 50 bytes): #{decrypted_data[0..49].inspect}"

      decrypted_data
    end
  end

  def initialize(channel = nil)
    @channel = channel
  end

  def encrypt_attachment(attachment)
    return { error: 'Attachment not found' } unless attachment&.file&.attached?

    begin
      # Download attachment to temporary file
      temp_file = Tempfile.new(['attachment', File.extname(attachment.file.filename.to_s)])
      temp_file.binmode

      attachment.file.download do |chunk|
        temp_file.write(chunk)
      end

      temp_file.rewind

      # Read and encrypt the file
      file_content = File.binread(temp_file.path)
      encrypted_content, encryption_key = self.class.encrypt(file_content)

      # Calculate file hash for verification
      file_hash = Digest::SHA256.hexdigest(file_content)

      # Store encryption metadata
      update_attachment_encryption(attachment, {
        encryption_key: Base64.encode64(encryption_key),
        file_hash: file_hash,
        algorithm: AES_256_CTR
      })

      # Store encrypted content
      store_encrypted_file(attachment, Base64.encode64(encrypted_content))

      {
        success: true,
        attachment_id: attachment.id,
        encryption_key: encryption_key,
        file_hash: file_hash
      }
    rescue StandardError => e
      {
        error: "Attachment encryption failed: #{e.message}"
      }
    ensure
      temp_file&.close
      temp_file&.unlink
    end
  end

  def decrypt_attachment(attachment, encryption_key = nil)
    return { error: 'Attachment not encrypted' } unless attachment.encrypted?

    encryption_key ||= attachment.encryption_key
    return { error: 'No encryption key provided' } unless encryption_key

    begin
      # Retrieve encrypted content
      encrypted_content_b64 = get_encrypted_content(attachment)
      return { error: 'Encrypted content not found' } unless encrypted_content_b64

      encrypted_content = Base64.decode64(encrypted_content_b64)

      # Decrypt the content
      decrypted_content = self.class.decrypt(encrypted_content, encryption_key)

      # Verify hash if available
      if attachment.file_hash
        actual_hash = Digest::SHA256.hexdigest(decrypted_content)
        unless actual_hash == attachment.file_hash
          return { error: 'File integrity check failed: hash mismatch' }
        end
      end

      {
        success: true,
        content: decrypted_content,
        filename: attachment.file.filename.to_s,
        content_type: attachment.file.content_type,
        size: decrypted_content.length,
        verified: attachment.file_hash.present?
      }
    rescue StandardError => e
      {
        error: "Attachment decryption failed: #{e.message}"
      }
    end
  end

  def generate_secure_download_url(attachment, expires_in = 1.hour)
    return { error: 'Attachment not encrypted' } unless attachment.encrypted?

    # Generate temporary download token
    download_token = SecureRandom.hex(32)

    # Store download permission in Redis
    Redis.current.setex(
      "apple_encrypted_download:#{download_token}",
      expires_in.to_i,
      {
        attachment_id: attachment.id,
        channel_id: @channel&.id,
        created_at: Time.current.iso8601,
        expires_at: expires_in.from_now.iso8601
      }.to_json
    )

    {
      success: true,
      download_url: secure_download_url(download_token),
      expires_at: expires_in.from_now,
      token: download_token
    }
  end

  def validate_download_token(token)
    redis_key = "apple_encrypted_download:#{token}"
    token_data = Redis.current.get(redis_key)

    return { valid: false, error: 'Invalid or expired token' } unless token_data

    begin
      data = JSON.parse(token_data)
      attachment = Attachment.find(data['attachment_id'])

      {
        valid: true,
        attachment: attachment,
        channel_id: data['channel_id'],
        expires_at: data['expires_at']
      }
    rescue JSON::ParserError, ActiveRecord::RecordNotFound
      { valid: false, error: 'Invalid token data' }
    end
  end

  private

  def update_attachment_encryption(attachment, encryption_result)
    attachment.update!(
      encrypted: true,
      encryption_key: encryption_result[:encryption_key],
      encryption_algorithm: encryption_result[:algorithm],
      file_hash: encryption_result[:file_hash]
    )
  end

  def store_encrypted_file(attachment, encrypted_content)
    # Store encrypted content in a secure location
    storage_key = "encrypted_attachment_#{attachment.id}"

    # Store in Redis temporarily (in production, use proper storage like S3)
    Redis.current.setex(
      "apple_encrypted_files:#{storage_key}",
      24.hours.to_i,
      encrypted_content
    )

    # Update attachment with storage reference
    attachment.update!(storage_key: storage_key)
  end

  def get_encrypted_content(attachment)
    storage_key = attachment.storage_key
    return nil unless storage_key

    Redis.current.get("apple_encrypted_files:#{storage_key}")
  end

  def secure_download_url(token)
    "#{ENV.fetch('BASE_URL', 'http://localhost:3000')}/apple_messages_for_business/encrypted_download/#{token}"
  end
end