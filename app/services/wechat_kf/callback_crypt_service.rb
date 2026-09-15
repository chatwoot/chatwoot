class WechatKf::CallbackCryptService
  class InvalidCallback < StandardError; end

  def initialize(integration)
    @integration = integration
  end

  def decrypt(encrypted:, signature:, timestamp:, nonce:)
    verify_signature!(encrypted, signature, timestamp, nonce)
    extract_message(decrypt_bytes(encrypted))
  rescue OpenSSL::Cipher::CipherError, ArgumentError
    raise InvalidCallback
  end

  private

  def verify_signature!(encrypted, signature, timestamp, nonce)
    expected = Digest::SHA1.hexdigest([@integration.callback_token, timestamp, nonce, encrypted].sort.join)
    raise InvalidCallback unless ActiveSupport::SecurityUtils.secure_compare(expected, signature.to_s)
  end

  def decrypt_bytes(encrypted)
    key = Base64.decode64("#{@integration.encoding_aes_key}=")
    cipher = OpenSSL::Cipher.new('aes-256-cbc')
    cipher.decrypt
    cipher.key = key
    cipher.iv = key.byteslice(0, 16)
    cipher.padding = 0
    padded = cipher.update(Base64.strict_decode64(encrypted)) + cipher.final
    padding_length = padded.getbyte(-1)
    valid_padding = padding_length&.between?(1, 32) && padded.byteslice(-padding_length, padding_length) == padding_length.chr * padding_length
    raise InvalidCallback unless valid_padding

    padded.byteslice(0, padded.bytesize - padding_length)
  end

  def extract_message(plaintext)
    raise InvalidCallback if plaintext.bytesize < 20

    message_size = plaintext.byteslice(16, 4).unpack1('N')
    raise InvalidCallback if message_size > plaintext.bytesize - 20

    message = plaintext.byteslice(20, message_size)
    receive_id = plaintext.byteslice(20 + message_size, plaintext.bytesize)
    raise InvalidCallback unless message && receive_id == @integration.corp_id

    message
  end
end
