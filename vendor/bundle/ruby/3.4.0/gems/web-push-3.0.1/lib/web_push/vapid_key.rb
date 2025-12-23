# frozen_string_literal: true

module WebPush
  # Class for abstracting the generation and encoding of elliptic curve public and private keys for use with the VAPID protocol
  #
  # @attr_reader [OpenSSL::PKey::EC] :curve the OpenSSL elliptic curve instance
  class VapidKey
    # Create a VapidKey instance from encoded elliptic curve public and private keys
    #
    # @return [WebPush::VapidKey] a VapidKey instance for the given public and private keys
    def self.from_keys(public_key, private_key)
      key = new
      key.set_keys! public_key, private_key
      key
    end

    # Create a VapidKey instance from pem encoded elliptic curve public and private keys
    #
    # @return [WebPush::VapidKey] a VapidKey instance for the given public and private keys
    def self.from_pem(pem)
      new(OpenSSL::PKey.read(pem))
    end

    attr_reader :curve

    def initialize(pkey = nil)
      @curve = pkey
      @curve = OpenSSL::PKey::EC.generate('prime256v1') if @curve.nil?
    end

    # Retrieve the encoded elliptic curve public key for VAPID protocol
    #
    # @return [String] encoded binary representation of 65-byte VAPID public key
    def public_key
      encode64(curve.public_key.to_bn.to_s(2))
    end

    # Retrieve the encoded elliptic curve public key suitable for the Web Push request
    #
    # @return [String] the encoded VAPID public key for us in 'Encryption' header
    def public_key_for_push_header
      trim_encode64(curve.public_key.to_bn.to_s(2))
    end

    # Retrive the encoded elliptic curve private key for VAPID protocol
    #
    # @return [String] base64 urlsafe-encoded binary representation of 32-byte VAPID private key
    def private_key
      encode64(curve.private_key.to_s(2))
    end

    def public_key=(key)
      set_keys! key, nil
    end

    def private_key=(key)
      set_keys! nil, key
    end
    
    def set_keys!(public_key = nil, private_key = nil)
      if public_key.nil?
        public_key = curve.public_key
      else
        public_key = OpenSSL::PKey::EC::Point.new(group, to_big_num(public_key))
      end

      if private_key.nil?
        private_key = curve.private_key
      else
        private_key = to_big_num(private_key)
      end

      asn1 = OpenSSL::ASN1::Sequence([
        OpenSSL::ASN1::Integer.new(1),
        # Not properly padded but OpenSSL doesn't mind
        OpenSSL::ASN1::OctetString(private_key.to_s(2)),
        OpenSSL::ASN1::ObjectId('prime256v1', 0, :EXPLICIT),
        OpenSSL::ASN1::BitString(public_key.to_octet_string(:uncompressed), 1, :EXPLICIT),
      ])

      der = asn1.to_der

      @curve = OpenSSL::PKey::EC.new(der)
    end

    def curve_name
      group.curve_name
    end

    def group
      curve.group
    end

    def to_h
      { public_key: public_key, private_key: private_key }
    end
    alias to_hash to_h

    def to_pem
      private_key_to_pem + public_key_to_pem
    end

    def private_key_to_pem
      curve.to_pem
    end

    def public_key_to_pem
      curve.public_to_pem
    end

    def inspect
      "#<#{self.class}:#{object_id.to_s(16)} #{to_h.map { |k, v| ":#{k}=#{v}" }.join(' ')}>"
    end

    private

    def to_big_num(key)
      OpenSSL::BN.new(WebPush.decode64(key), 2)
    end

    def encode64(bin)
      WebPush.encode64(bin)
    end

    def trim_encode64(bin)
      encode64(bin).delete('=')
    end
  end
end
