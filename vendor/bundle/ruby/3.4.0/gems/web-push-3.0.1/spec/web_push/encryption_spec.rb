require 'spec_helper'

describe WebPush::Encryption do
  describe '#encrypt' do
    let(:curve) do
      group = 'prime256v1'
      OpenSSL::PKey::EC.generate(group)
    end

    let(:p256dh) do
      ecdh_key = curve.public_key.to_bn.to_s(2)
      Base64.urlsafe_encode64(ecdh_key)
    end

    let(:auth) { Base64.urlsafe_encode64(Random.new.bytes(16)) }

    it 'returns ECDH encrypted cipher text, salt, and server_public_key' do
      payload = WebPush::Encryption.encrypt('Hello World', p256dh, auth)
      expect(decrypt(payload)).to eq('Hello World')
    end

    it 'returns error when message is blank' do
      expect { WebPush::Encryption.encrypt(nil, p256dh, auth) }.to raise_error(ArgumentError)
      expect { WebPush::Encryption.encrypt('', p256dh, auth) }.to raise_error(ArgumentError)
    end

    it 'returns error when p256dh is blank' do
      expect { WebPush::Encryption.encrypt('Hello world', nil, auth) }.to raise_error(ArgumentError)
      expect { WebPush::Encryption.encrypt('Hello world', '', auth) }.to raise_error(ArgumentError)
    end

    it 'returns error when auth is blank' do
      expect { WebPush::Encryption.encrypt('Hello world', p256dh, '') }.to raise_error(ArgumentError)
      expect { WebPush::Encryption.encrypt('Hello world', p256dh, nil) }.to raise_error(ArgumentError)
    end

    # Bug fix for https://github.com/zaru/webpush/issues/22
    it 'handles unpadded base64 encoded subscription keys' do
      unpadded_p256dh = p256dh.gsub(/=*\Z/, '')
      unpadded_auth = auth.gsub(/=*\Z/, '')

      payload = WebPush::Encryption.encrypt('Hello World', unpadded_p256dh, unpadded_auth)
      expect(decrypt(payload)).to eq('Hello World')
    end

    def decrypt payload
      salt = payload.byteslice(0, 16)
      rs = payload.byteslice(16, 4).unpack("N*").first
      idlen = payload.byteslice(20).unpack("C*").first
      serverkey16bn = payload.byteslice(21, idlen)
      ciphertext = payload.byteslice(21 + idlen, rs)

      expect(payload.bytesize).to eq(21 + idlen + rs)

      group_name = 'prime256v1'
      group = OpenSSL::PKey::EC::Group.new(group_name)
      server_public_key_bn = OpenSSL::BN.new(serverkey16bn.unpack('H*').first, 16)
      server_public_key = OpenSSL::PKey::EC::Point.new(group, server_public_key_bn)
      shared_secret = curve.dh_compute_key(server_public_key)

      client_public_key_bn = curve.public_key.to_bn
      client_auth_token = WebPush.decode64(auth)

      info = "WebPush: info\0" + client_public_key_bn.to_s(2) + server_public_key_bn.to_s(2)
      content_encryption_key_info = "Content-Encoding: aes128gcm\0"
      nonce_info = "Content-Encoding: nonce\0"

      prk = OpenSSL::KDF.hkdf(shared_secret, salt: client_auth_token, info: info, hash: 'SHA256', length: 32)

      content_encryption_key = OpenSSL::KDF.hkdf(prk, salt: salt, info: content_encryption_key_info, hash: 'SHA256', length: 16)
      nonce = OpenSSL::KDF.hkdf(prk, salt: salt, info: nonce_info, hash: 'SHA256', length: 12)

      decrypt_ciphertext(ciphertext, content_encryption_key, nonce)
    end

    def decrypt_ciphertext(ciphertext, content_encryption_key, nonce)
      secret_data = ciphertext.byteslice(0, ciphertext.bytesize-16)
      auth = ciphertext.byteslice(ciphertext.bytesize-16, ciphertext.bytesize)
      decipher = OpenSSL::Cipher.new('aes-128-gcm')
      decipher.decrypt
      decipher.key = content_encryption_key
      decipher.iv = nonce
      decipher.auth_tag = auth

      decrypted = decipher.update(secret_data) + decipher.final

      e = decrypted.byteslice(-2, decrypted.bytesize)
      expect(e).to eq("\2\0")

      decrypted.byteslice(0, decrypted.bytesize-2)
    end
  end
end
