require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
describe 'Message Serializer Configuration' do
  # rubocop:enable RSpec/DescribeClass

  let(:account) { create(:account) }
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new('hello'), filename: 'hello.txt', content_type: 'text/plain')
  end

  def binary_format_verifier(salt)
    ActiveSupport::MessageVerifier.new(Rails.application.key_generator.generate_key(salt), serializer: Marshal)
  end

  before { allow(Marshal).to receive(:load).and_call_original }

  it 'uses JSON for signed and encrypted messages' do
    expect(ActiveSupport::Messages::Codec.default_serializer).to eq(:json)
  end

  describe 'application message verifiers' do
    let(:verifier) { Rails.application.message_verifier('message_serializer_spec') }

    it 'round trips JSON payloads' do
      token = verifier.generate({ 'id' => 1, 'name' => 'test' }, purpose: :spec, expires_in: 1.hour)

      expect(verifier.verified(token, purpose: :spec)).to eq({ 'id' => 1, 'name' => 'test' })
    end

    it 'rejects messages in the binary format without loading them' do
      token = binary_format_verifier('message_serializer_spec').generate(1..2, purpose: :spec)

      expect { verifier.verified(token, purpose: :spec) }.to raise_error(RuntimeError, 'Unsupported serialization format')
      expect(Marshal).not_to have_received(:load)
    end
  end

  describe 'message encryptors' do
    let(:encryptor) { ActiveSupport::MessageEncryptor.new(SecureRandom.bytes(32)) }

    it 'round trips string payloads' do
      expect(encryptor.decrypt_and_verify(encryptor.encrypt_and_sign('123456'))).to eq('123456')
    end

    it 'rejects messages in the binary format without loading them' do
      key = SecureRandom.bytes(32)
      ciphertext = ActiveSupport::MessageEncryptor.new(key, serializer: Marshal).encrypt_and_sign(1..2)

      expect { ActiveSupport::MessageEncryptor.new(key).decrypt_and_verify(ciphertext) }
        .to raise_error(ActiveSupport::MessageEncryptor::InvalidMessage)
      expect(Marshal).not_to have_received(:load)
    end
  end

  describe 'signed global ids' do
    it 'round trips' do
      sgid = account.to_sgid(expires_in: 15.minutes, for: 'default').to_s

      expect(GlobalID::Locator.locate_signed(sgid, for: 'default')).to eq(account)
    end
  end

  describe 'active storage' do
    it 'round trips blob signed ids' do
      expect(ActiveStorage::Blob.find_signed(blob.signed_id)).to eq(blob)
    end

    it 'round trips variation keys' do
      key = ActiveStorage::Variation.encode(resize_to_fill: [250, nil])

      expect(ActiveStorage::Variation.decode(key).transformations).to eq(resize_to_fill: [250, nil])
    end

    it 'keeps blob signed ids issued in the binary format working' do
      signed_id = binary_format_verifier('ActiveStorage').generate(blob.id, purpose: :blob_id)

      expect(ActiveStorage::Blob.find_signed(signed_id)).to eq(blob)
      expect(Marshal).not_to have_received(:load)
    end

    it 'reads larger blob ids issued in the binary format' do
      [123, (2**30) - 1, 2**30, 2**40].each do |id|
        signed_id = binary_format_verifier('ActiveStorage').generate(id, purpose: :blob_id)

        expect(ActiveStorage.verifier.verified(signed_id, purpose: :blob_id)).to eq(id)
      end
    end

    it 'rejects other payloads in the binary format without loading them' do
      [{ key: 'abc' }, 'abc', 1..2, -1].each do |payload|
        token = binary_format_verifier('ActiveStorage').generate(payload, purpose: :blob_key)

        expect { ActiveStorage.verifier.verified(token, purpose: :blob_key) }
          .to raise_error(RuntimeError, 'Unsupported serialization format')
      end
      expect(Marshal).not_to have_received(:load)
    end
  end

  describe 'active storage blob urls', type: :request do
    it 'serves a blob through the signed redirect and disk urls' do
      get rails_blob_path(blob, disposition: :inline)
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq('hello')
    end
  end
end
