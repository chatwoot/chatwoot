class AppleMessagesForBusiness::KeyPairService
  include Singleton

  def initialize
    @key_cache = {}
  end

  def generate_ecc_key_pair
    key = OpenSSL::PKey::EC.new('prime256v1')
    key.generate_key

    {
      private_key: key.to_pem,
      public_key: extract_public_key(key),
      key_id: generate_key_id
    }
  end

  def get_key_pair(channel_id)
    @key_cache[channel_id] ||= generate_and_store_key_pair(channel_id)
  end

  def rotate_key_pair(channel_id)
    @key_cache.delete(channel_id)
    generate_and_store_key_pair(channel_id)
  end

  private

  def extract_public_key(key)
    public_key = key.public_key
    point = public_key.to_bn(:uncompressed)

    # Extract x and y coordinates (remove the 0x04 prefix)
    hex_string = point.to_s(16)
    x_coord = hex_string[2, 64]
    y_coord = hex_string[66, 64]

    {
      x: Base64.urlsafe_encode64([x_coord].pack('H*')),
      y: Base64.urlsafe_encode64([y_coord].pack('H*')),
      crv: 'P-256',
      kty: 'EC'
    }
  end

  def generate_key_id
    SecureRandom.hex(16)
  end

  def generate_and_store_key_pair(channel_id)
    key_pair = generate_ecc_key_pair

    # Store in encrypted format
    channel = Channel::AppleMessagesForBusiness.find(channel_id)
    encrypted_keys = encrypt_keys(key_pair)
    channel.update!(oauth2_providers: channel.oauth2_providers.merge(keys: encrypted_keys))

    key_pair
  end

  def encrypt_keys(key_pair)
    cipher = OpenSSL::Cipher.new('AES-256-GCM')
    cipher.encrypt

    key = cipher.random_key
    iv = cipher.random_iv

    encrypted_data = cipher.update(key_pair.to_json) + cipher.final
    auth_tag = cipher.auth_tag

    {
      encrypted_data: Base64.encode64(encrypted_data),
      key: Base64.encode64(key),
      iv: Base64.encode64(iv),
      auth_tag: Base64.encode64(auth_tag)
    }
  end
end