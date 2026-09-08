require 'rails_helper'

RSpec.describe Shopify::PendingInstallation do
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
  let(:generation_key) { "shopify_pending_install_generation:#{shop}" }
  let(:authorization_key) { "shopify_pending_install_authorization:#{shop}" }
  let(:lock_key) { "shopify_pending_install_lock:#{shop}" }

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
    Redis::Alfred.delete(generation_key)
    Redis::Alfred.delete(authorization_key)
    Redis::Alfred.delete(lock_key)
  end

  it 'creates an encrypted pending installation' do
    created_token = described_class.create(access_token: access_token, shop: shop, scope: scope)

    expect(created_token).to match(described_class::TOKEN_FORMAT)
  ensure
    Redis::Alfred.delete("shopify_pending_install:#{created_token}") if created_token
  end

  it 'claims an encrypted pending installation' do
    pending_installation = described_class.claim(token: token)

    expect(pending_installation.data).to eq(
      'access_token' => access_token,
      'shop' => shop,
      'scope' => scope
    )
  ensure
    pending_installation&.release!
  end

  it 'identifies an available pending installation token' do
    expect(described_class.pending?(token: token)).to be(true)
    expect(described_class.pending?(token: 'invalid-token')).to be(false)
  end

  it 'invalidates tokens created before Shopify lifecycle cleanup' do
    created_token = described_class.create(access_token: access_token, shop: shop, scope: scope)

    Shopify::PendingInstallationLifecycle.invalidate!(shop: shop)

    expect(described_class.pending?(token: created_token)).to be(false)
    expect do
      described_class.claim(token: created_token)
    end.to raise_error(described_class::InvalidToken, 'Invalid or expired install token')
  ensure
    Redis::Alfred.delete("shopify_pending_install:#{created_token}") if created_token
    Redis::Alfred.delete("shopify_pending_install_claim:#{created_token}") if created_token
  end

  it 'rejects token creation from an OAuth flow that predates cleanup' do
    shop_generation = Shopify::PendingInstallationLifecycle.generation(shop: shop)
    Shopify::PendingInstallationLifecycle.invalidate!(shop: shop)

    expect do
      described_class.create(
        access_token: access_token,
        shop: shop,
        scope: scope,
        shop_generation: shop_generation
      )
    end.to raise_error(described_class::InvalidToken, 'Shopify installation is no longer active')
  end

  it 'allows a fresh installation after lifecycle cleanup' do
    Shopify::PendingInstallationLifecycle.invalidate!(shop: shop)
    created_token = described_class.create(access_token: access_token, shop: shop, scope: scope)
    pending_installation = described_class.claim(token: created_token)

    expect(pending_installation.data['generation']).to eq(1)
  ensure
    pending_installation&.consume!
    Redis::Alfred.delete("shopify_pending_install:#{created_token}") if created_token
  end

  it 'does not let a stale lifecycle event invalidate a newer authorization' do
    authorization_started_at = Time.iso8601('2026-09-08T10:00:00Z')
    authorization = Shopify::PendingInstallationLifecycle.start_authorization!(shop: shop, started_at: authorization_started_at)

    invalidated = Shopify::PendingInstallationLifecycle.invalidate!(shop: shop, occurred_at: authorization_started_at - 1.minute)

    expect(invalidated).to be(false)
    expect(authorization[:generation]).to eq(0)
    expect(Shopify::PendingInstallationLifecycle.generation(shop: shop)).to eq(0)
  end

  it 'invalidates authorization when the lifecycle event is newer' do
    authorization_started_at = Time.iso8601('2026-09-08T10:00:00Z')
    Shopify::PendingInstallationLifecycle.start_authorization!(shop: shop, started_at: authorization_started_at)

    invalidated = Shopify::PendingInstallationLifecycle.invalidate!(shop: shop, occurred_at: authorization_started_at + 1.minute)

    expect(invalidated).to be(true)
    expect(Shopify::PendingInstallationLifecycle.generation(shop: shop)).to eq(1)
  end

  it 'serializes generation validation with lifecycle invalidation' do
    created_token = described_class.create(access_token: access_token, shop: shop, scope: scope)
    pending_installation = described_class.claim(token: created_token)
    inside_installation = Queue.new
    finish_installation = Queue.new

    installation_thread = Thread.new do
      pending_installation.with_valid_generation! do
        inside_installation << true
        finish_installation.pop
      end
    end
    inside_installation.pop

    invalidation_thread = Thread.new { Shopify::PendingInstallationLifecycle.invalidate!(shop: shop) }
    expect(invalidation_thread.join(0.05)).to be_nil

    finish_installation << true
    installation_thread.join
    invalidation_thread.join

    expect(Shopify::PendingInstallationLifecycle.generation(shop: shop)).to eq(1)
  ensure
    finish_installation << true if finish_installation && finish_installation.empty?
    installation_thread&.join
    invalidation_thread&.join
    pending_installation&.release!
    Redis::Alfred.delete("shopify_pending_install:#{created_token}") if created_token
  end

  it 'allows only one active claim' do
    pending_installation = described_class.claim(token: token)

    expect do
      described_class.claim(token: token)
    end.to raise_error(described_class::AlreadyClaimed, 'Install token is already being used')
  ensure
    pending_installation&.release!
  end

  it 'allows a retry after the claim is released' do
    pending_installation = described_class.claim(token: token)
    pending_installation.release!

    retried_installation = described_class.claim(token: token)
    expect(retried_installation.data['shop']).to eq(shop)
  ensure
    retried_installation&.release!
  end

  it 'prevents a token bound by a failed attempt from moving to another account' do
    pending_installation = described_class.claim(token: token, account_id: 1)
    pending_installation.release!

    expect do
      described_class.claim(token: token, account_id: 2)
    end.to raise_error(described_class::InvalidToken, 'Install token cannot be used by this account')
  end

  it 'removes a new-account binding when signup fails' do
    pending_installation = described_class.claim(token: token)
    pending_installation.bind_to_account!(1)
    pending_installation.release!(unbind: true)

    retried_installation = described_class.claim(token: token)

    expect(retried_installation.data['account_id']).to be_nil
  ensure
    retried_installation&.release!
  end

  it 'prevents replay after the claim is consumed' do
    pending_installation = described_class.claim(token: token)
    pending_installation.consume!

    expect(Redis::Alfred.get(payload_key)).to be_nil
    expect(Redis::Alfred.get(claim_key)).to be_nil

    expect do
      described_class.claim(token: token)
    end.to raise_error(described_class::InvalidToken, 'Invalid or expired install token')
  end

  it 'accepts a lost transaction reply when both keys were consumed' do
    pending_installation = described_class.claim(token: token)
    Redis::Alfred.delete(payload_key)
    Redis::Alfred.delete(claim_key)
    allow(Redis::Alfred).to receive(:with).and_raise(Redis::CannotConnectError, 'connection lost')
    allow(pending_installation).to receive(:consume_state).and_return(:consumed)

    expect { pending_installation.consume! }.not_to raise_error
  end

  it 'classifies a surviving payload as not consumed after the claim expires' do
    pending_installation = described_class.claim(token: token)
    Redis::Alfred.delete(claim_key)

    expect(pending_installation.send(:consume_state)).to eq(:not_consumed)
  end

  it 'does not consume the payload when the claim is no longer owned' do
    pending_installation = described_class.claim(token: token)
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
      described_class.claim(token: '../invalid')
    end.to raise_error(described_class::InvalidToken, 'Invalid or expired install token')
  end

  it 'releases the claim when the encrypted payload is invalid' do
    Redis::Alfred.set(payload_key, 'invalid-encrypted-payload')

    expect do
      described_class.claim(token: token)
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

  it 'normalizes the shop domain before storing it' do
    created_token = described_class.create(access_token: access_token, shop: 'My-Store.MyShopify.Com', scope: scope)
    pending_installation = described_class.claim(token: created_token)

    expect(pending_installation.data['shop']).to eq('my-store.myshopify.com')
  ensure
    pending_installation&.consume!
    Redis::Alfred.delete("shopify_pending_install:#{created_token}") if created_token
  end

  it 'rejects invalid shop domains before storing credentials' do
    expect(Redis::SecureStorage).not_to receive(:set)

    expect do
      described_class.create(access_token: access_token, shop: 'example.com', scope: scope)
    end.to raise_error(described_class::InvalidToken, 'Invalid shop domain')
  end

  it 'rejects a trailing hyphen in the shop label before storing credentials' do
    expect(Redis::SecureStorage).not_to receive(:set)

    expect do
      described_class.create(access_token: access_token, shop: 'bad-.myshopify.com', scope: scope)
    end.to raise_error(described_class::InvalidToken, 'Invalid shop domain')
  end

  it 'rejects an encrypted payload with an invalid shop domain' do
    Redis::SecureStorage.set(
      payload_key,
      { access_token: access_token, shop: 'example.com', scope: scope },
      10.minutes
    )

    expect do
      described_class.claim(token: token)
    end.to raise_error(described_class::InvalidToken, 'Invalid or expired install token')
  end
end
