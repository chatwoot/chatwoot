require 'rails_helper'

RSpec.describe Shopify::PendingInstallation do
  let(:account_id) { 123 }
  let(:access_token) { 'shopify-access-token' }
  let(:shop) { 'my-store.myshopify.com' }
  let(:scope) { 'read_customers,read_orders' }
  let(:encryption_env) do
    {
      'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY' => 'primary-key',
      'ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY' => 'deterministic-key',
      'ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT' => 'key-derivation-salt'
    }
  end
  let(:token) { SecureRandom.hex(16) }
  let(:payload_key) { "shopify_pending_install:#{token}" }
  let(:claim_key) { "shopify_pending_install_claim:#{token}" }

  around do |example|
    with_modified_env(encryption_env) { example.run }
  end

  before do
    Redis::SecureStorage.set(
      payload_key,
      { access_token: access_token, shop: shop, scope: scope },
      10.minutes
    )
  end

  after do
    Redis::Alfred.delete(payload_key)
    Redis::Alfred.delete(claim_key)
  end

  it 'creates an encrypted pending installation' do
    created_token = described_class.create(access_token: access_token, shop: shop, scope: scope)

    expect(created_token).to match(described_class::TOKEN_FORMAT)
  ensure
    Redis::Alfred.delete("shopify_pending_install:#{created_token}") if created_token
  end

  it 'claims an encrypted pending installation' do
    pending_installation = described_class.claim(token: token, account_id: account_id)

    expect(pending_installation.data).to eq(
      'access_token' => access_token,
      'shop' => shop,
      'scope' => scope
    )
  ensure
    pending_installation&.release!
  end

  it 'allows only one active claim' do
    pending_installation = described_class.claim(token: token, account_id: account_id)

    expect do
      described_class.claim(token: token, account_id: account_id)
    end.to raise_error(described_class::AlreadyClaimed, 'Install token is already being used')
  ensure
    pending_installation&.release!
  end

  it 'allows a retry after the claim is released' do
    pending_installation = described_class.claim(token: token, account_id: account_id)
    pending_installation.release!

    retried_installation = described_class.claim(token: token, account_id: account_id)
    expect(retried_installation.data['shop']).to eq(shop)
  ensure
    retried_installation&.release!
  end

  it 'prevents replay after the claim is consumed' do
    pending_installation = described_class.claim(token: token, account_id: account_id)
    pending_installation.consume!

    expect(Redis::Alfred.get(payload_key)).to be_nil
    expect(Redis::Alfred.get(claim_key)).to be_nil

    expect do
      described_class.claim(token: token, account_id: account_id)
    end.to raise_error(described_class::InvalidToken, 'Invalid or expired install token')
  end

  it 'accepts a lost transaction reply when both keys were consumed' do
    pending_installation = described_class.claim(token: token, account_id: account_id)
    Redis::Alfred.delete(payload_key)
    Redis::Alfred.delete(claim_key)
    allow(Redis::Alfred).to receive(:with).and_raise(Redis::CannotConnectError, 'connection lost')
    allow(pending_installation).to receive(:consume_state).and_return(:consumed)

    expect { pending_installation.consume! }.not_to raise_error
  end

  it 'classifies a surviving payload as not consumed after the claim expires' do
    pending_installation = described_class.claim(token: token, account_id: account_id)
    Redis::Alfred.delete(claim_key)

    expect(pending_installation.send(:consume_state)).to eq(:not_consumed)
  end

  it 'does not consume the payload when the claim is no longer owned' do
    pending_installation = described_class.claim(token: token, account_id: account_id)
    Redis::Alfred.set(claim_key, 'newer-claim', ex: described_class::CLAIM_TTL.to_i)

    expect do
      pending_installation.consume!
    end.to raise_error(described_class::AlreadyClaimed, 'Install token claim has expired')

    expect(Redis::SecureStorage.get(payload_key)).to be_present
    expect(Redis::Alfred.get(claim_key)).to eq('newer-claim')
  end

  it 'rejects malformed tokens before accessing Redis' do
    expect(Redis::Alfred).not_to receive(:set)

    expect do
      described_class.claim(token: '../invalid', account_id: account_id)
    end.to raise_error(described_class::InvalidToken, 'Invalid or expired install token')
  end

  it 'releases the claim when the encrypted payload is invalid' do
    Redis::Alfred.set(payload_key, 'invalid-encrypted-payload')

    expect do
      described_class.claim(token: token, account_id: account_id)
    end.to raise_error(described_class::InvalidToken)

    expect(Redis::Alfred.get(claim_key)).to be_nil
  end

  it 'requires encryption configuration when creating a pending installation' do
    with_modified_env(encryption_env.transform_values { nil }) do
      expect do
        described_class.create(access_token: access_token, shop: shop, scope: scope)
      end.to raise_error(Redis::SecureStorage::EncryptionNotConfigured)
    end
  end
end
