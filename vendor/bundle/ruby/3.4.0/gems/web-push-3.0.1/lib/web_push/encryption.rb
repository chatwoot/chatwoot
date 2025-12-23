# frozen_string_literal: true

module WebPush
  module Encryption
    extend self

    def encrypt(message, p256dh, auth)
      assert_arguments(message, p256dh, auth)

      group_name = 'prime256v1'
      hash = 'SHA256'
      salt = Random.new.bytes(16)

      server = OpenSSL::PKey::EC.generate(group_name)
      server_public_key_bn = server.public_key.to_bn

      group = OpenSSL::PKey::EC::Group.new(group_name)
      client_public_key_bn = OpenSSL::BN.new(WebPush.decode64(p256dh), 2)
      client_public_key = OpenSSL::PKey::EC::Point.new(group, client_public_key_bn)

      shared_secret = server.dh_compute_key(client_public_key)

      client_auth_token = WebPush.decode64(auth)

      info = "WebPush: info\0" + client_public_key_bn.to_s(2) + server_public_key_bn.to_s(2)
      content_encryption_key_info = "Content-Encoding: aes128gcm\0"
      nonce_info = "Content-Encoding: nonce\0"

      prk = OpenSSL::KDF.hkdf(shared_secret, salt: client_auth_token, info: info, hash: hash, length: 32)

      content_encryption_key = OpenSSL::KDF.hkdf(prk, salt: salt, info: content_encryption_key_info, hash: hash, length: 16)

      nonce = OpenSSL::KDF.hkdf(prk, salt: salt, info: nonce_info, hash: hash, length: 12)

      ciphertext = encrypt_payload(message, content_encryption_key, nonce)

      serverkey16bn = convert16bit(server_public_key_bn)
      rs = ciphertext.bytesize
      raise ArgumentError, "encrypted payload is too big" if rs > 4096

      aes128gcmheader = "#{salt}" + [rs].pack('N*') + [serverkey16bn.bytesize].pack('C*') + serverkey16bn

      aes128gcmheader + ciphertext
    end

    private

    def encrypt_payload(plaintext, content_encryption_key, nonce)
      cipher = OpenSSL::Cipher.new('aes-128-gcm')
      cipher.encrypt
      cipher.key = content_encryption_key
      cipher.iv = nonce
      text = cipher.update(plaintext)
      padding = cipher.update("\2\0")
      e_text = text + padding + cipher.final
      e_tag = cipher.auth_tag

      e_text + e_tag
    end

    def convert16bit(key)
      [key.to_s(16)].pack('H*')
    end

    def assert_arguments(message, p256dh, auth)
      raise ArgumentError, 'message cannot be blank' if blank?(message)
      raise ArgumentError, 'p256dh cannot be blank' if blank?(p256dh)
      raise ArgumentError, 'auth cannot be blank' if blank?(auth)
    end

    def blank?(value)
      value.nil? || value.empty?
    end
  end
end