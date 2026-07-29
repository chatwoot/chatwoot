require 'rails_helper'

RSpec.describe Redis::SecureStorage do
  let(:key) { "secure-storage-spec:#{SecureRandom.hex(8)}" }
  let(:encryption_env) do
    {
      'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY' => 'primary-key',
      'ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY' => 'deterministic-key',
      'ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT' => 'key-derivation-salt'
    }
  end

  around do |example|
    with_modified_env(encryption_env) { example.run }
  end

  after do
    Redis::Alfred.delete(key)
  end

  it 'stores encrypted data and decrypts it when read' do
    described_class.set(key, { access_token: 'secret-access-token' }, 10.minutes)

    raw_value = Redis::Alfred.get(key)
    expect(raw_value).not_to include('secret-access-token')
    expect(JSON.parse(described_class.get(key))).to eq('access_token' => 'secret-access-token')
  end

  it 'returns nil for corrupted encrypted data' do
    Redis::Alfred.set(key, 'not-encrypted-data')

    expect(described_class.get(key)).to be_nil
  end

  it 'refuses to write sensitive data without encryption configuration' do
    with_modified_env(encryption_env.transform_values { nil }) do
      expect do
        described_class.set(key, { access_token: 'secret-access-token' }, 10.minutes)
      end.to raise_error(described_class::EncryptionNotConfigured)
    end
  end

  it 'refuses to read sensitive data without encryption configuration' do
    with_modified_env(encryption_env.transform_values { nil }) do
      expect { described_class.get(key) }.to raise_error(described_class::EncryptionNotConfigured)
    end
  end
end
