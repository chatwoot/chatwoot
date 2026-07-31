require 'rails_helper'

RSpec.describe Shopify::PendingInstallation do
  let(:token) do
    described_class.create(
      access_token: 'shopify-token',
      shop: 'test-store.myshopify.com',
      scope: 'read_customers,read_orders'
    )
  end
  let(:payload_key) { "shopify_pending_install:#{token}" }
  let(:claim_key) { "shopify_pending_install_claim:#{token}" }

  after do
    Redis::Alfred.delete(payload_key)
    Redis::Alfred.delete(claim_key)
  end

  it 'allows only one active claim' do
    installation = described_class.claim(token: token, account_id: 1)

    expect do
      described_class.claim(token: token, account_id: 1)
    end.to raise_error(described_class::AlreadyClaimed)

    installation.release!
  end

  it 'keeps a released claim retryable for the same account' do
    installation = described_class.claim(token: token, account_id: 1)
    installation.release!

    retried_installation = described_class.claim(token: token, account_id: 1)

    expect(retried_installation.data['access_token']).to eq('shopify-token')
    retried_installation.release!
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
    installation = described_class.claim(token: token, account_id: 1)
    Redis::Alfred.set(claim_key, 'newer-claim', ex: described_class::CLAIM_TTL.to_i)

    expect do
      installation.consume!
    end.to raise_error(described_class::AlreadyClaimed, 'Install token claim has expired')

    expect(Redis::SecureStorage.get(payload_key)).to be_present
    expect(Redis::Alfred.get(claim_key)).to eq('newer-claim')
  end

  it 'prevents a token bound by a failed attempt from moving to another account' do
    installation = described_class.claim(token: token, account_id: 1)
    installation.release!

    expect do
      described_class.claim(token: token, account_id: 2)
    end.to raise_error(described_class::InvalidToken, 'Install token cannot be used by this account')
  end

  it 'removes a new-account binding when signup fails' do
    installation = described_class.claim(token: token)
    installation.bind_to_account!(1)
    installation.release!(unbind: true)

    retried_installation = described_class.claim(token: token)

    expect(retried_installation.data['account_id']).to be_nil
    retried_installation.release!
  end

  it 'removes the payload after a successful consumption' do
    installation = described_class.claim(token: token, account_id: 1)
    installation.consume!

    expect(Redis::Alfred.get(payload_key)).to be_nil
    expect(Redis::Alfred.get(claim_key)).to be_nil
    expect do
      described_class.claim(token: token, account_id: 1)
    end.to raise_error(described_class::InvalidToken)
  end
end
