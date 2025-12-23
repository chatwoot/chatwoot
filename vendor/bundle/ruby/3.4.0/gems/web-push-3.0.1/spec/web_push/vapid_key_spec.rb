require 'spec_helper'

describe WebPush::VapidKey do
  it 'generates an elliptic curve' do
    key = WebPush::VapidKey.new
    expect(key.curve).to be_a(OpenSSL::PKey::EC)
    expect(key.curve_name).to eq('prime256v1')
  end

  it 'returns an encoded public key' do
    key = WebPush::VapidKey.new

    expect(Base64.urlsafe_decode64(key.public_key).bytesize).to eq(65)
  end

  it 'returns an encoded private key' do
    key = WebPush::VapidKey.new

    expect(Base64.urlsafe_decode64(key.private_key).bytesize).to eq(32)
  end

  it 'pretty prints encoded keys' do
    key = WebPush::VapidKey.new
    printed = key.inspect

    expect(printed).to match(/public_key=#{key.public_key}/)
    expect(printed).to match(/private_key=#{key.private_key}/)
  end

  it 'returns hash of public and private keys' do
    key = WebPush::VapidKey.new
    hash = key.to_h

    expect(hash[:public_key]).to eq(key.public_key)
    expect(hash[:private_key]).to eq(key.private_key)
  end

  it 'returns pem of public and private keys' do
    key = WebPush::VapidKey.new
    pem = key.to_pem

    expect(pem).to include('-----BEGIN EC PRIVATE KEY-----')
    expect(pem).to include('-----BEGIN PUBLIC KEY-----')
  end

  it 'returns the correct public and private keys in pem format' do
    public_key_base64 = 'BMA-wciFTkEq2waVGB2hg8cSyiRiMcsIvIYQb3LkLOmBheh3YC6NB2GtE9t6YgaXt428rp7bC9JjuPtAY9AQaR8='
    private_key_base64 = '4MwLvN1Cpxe43AV9fa4BiS-SPp51gWlhv9c6bb_XSJ4='
    key = WebPush::VapidKey.from_keys(public_key_base64, private_key_base64)
    pem = key.to_pem
    expected_pem = <<~PEM
      -----BEGIN EC PRIVATE KEY-----
      MHcCAQEEIODMC7zdQqcXuNwFfX2uAYkvkj6edYFpYb/XOm2/10ieoAoGCCqGSM49
      AwEHoUQDQgAEwD7ByIVOQSrbBpUYHaGDxxLKJGIxywi8hhBvcuQs6YGF6HdgLo0H
      Ya0T23piBpe3jbyuntsL0mO4+0Bj0BBpHw==
      -----END EC PRIVATE KEY-----
      -----BEGIN PUBLIC KEY-----
      MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEwD7ByIVOQSrbBpUYHaGDxxLKJGIx
      ywi8hhBvcuQs6YGF6HdgLo0HYa0T23piBpe3jbyuntsL0mO4+0Bj0BBpHw==
      -----END PUBLIC KEY-----
    PEM
    expect(pem).to eq(expected_pem)
  end

  it 'can return the private key in pem format' do
    pem = WebPush::VapidKey.new.private_key_to_pem
    expect(pem).to include('-----BEGIN EC PRIVATE KEY-----')
  end

  it 'can return the public key in pem format' do
    pem = WebPush::VapidKey.new.public_key_to_pem
    expect(pem).to include('-----BEGIN PUBLIC KEY-----')
  end

  it 'imports pem of public and private keys' do
    pem = WebPush::VapidKey.new.to_pem
    key = WebPush::VapidKey.from_pem pem

    expect(key.to_pem).to eq(pem)
  end

  describe 'self.from_keys' do
    it 'returns an encoded public key' do
      key = WebPush::VapidKey.from_keys(vapid_public_key, vapid_private_key)

      expect(key.public_key).to eq(vapid_public_key)
    end

    it 'returns an encoded private key' do
      key = WebPush::VapidKey.from_keys(vapid_public_key, vapid_private_key)

      expect(key.private_key).to eq(vapid_private_key)
    end
  end
end
