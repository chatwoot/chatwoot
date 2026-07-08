require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::FilteredCountStore do
  let(:account_id) { 1 }
  let(:user_id) { 2 }
  let(:filter_id) { 3 }
  let(:built_at) { Time.zone.parse('2026-06-29 10:00:00 UTC') }

  after do
    redis_keys.each { |key| Redis::Alfred.delete(key) }
  end

  describe 'key builders' do
    it 'builds V2 keys for built-in filters, folder indexes, and saved filters' do
      expect(described_class.conversation_version_key(account_id)).to eq(
        'UNREAD_CONVERSATIONS::V2::ACCOUNT::1::CONVERSATION_VERSION'
      )
      expect(described_class.built_in_filter_version_key(account_id, user_id)).to eq(
        'UNREAD_CONVERSATIONS::V2::ACCOUNT::1::USER::2::BUILT_IN_FILTER_VERSION'
      )
      expect(described_class.built_in_filter_counts_key(account_id, user_id)).to eq(
        'UNREAD_CONVERSATIONS::V2::ACCOUNT::1::USER::2::BUILT_IN_FILTER_COUNTS'
      )
      expect(described_class.folder_index_key(account_id, user_id)).to eq(
        'UNREAD_CONVERSATIONS::V2::ACCOUNT::1::USER::2::FOLDER_INDEX'
      )
      expect(described_class.filter_count_key(account_id, filter_id)).to eq(
        'UNREAD_CONVERSATIONS::V2::ACCOUNT::1::FILTER::3::COUNT'
      )
    end
  end

  describe 'version metadata' do
    it 'defaults missing version keys to zero' do
      expect(described_class.conversation_version(account_id)).to eq(0)
      expect(described_class.built_in_filter_version(account_id: account_id, user_id: user_id)).to eq(0)
      expect(described_class.folder_index_version(account_id: account_id, user_id: user_id)).to eq(0)
      expect(described_class.filter_version(account_id: account_id, filter_id: filter_id)).to eq(0)
    end

    it 'increments independent version keys' do
      expect(described_class.bump_conversation_version!(account_id)).to eq(1)
      expect(described_class.bump_built_in_filter_version!(account_id: account_id, user_id: user_id)).to eq(1)
      expect(described_class.bump_folder_index_version!(account_id: account_id, user_id: user_id)).to eq(1)
      expect(described_class.bump_filter_version!(account_id: account_id, filter_id: filter_id)).to eq(1)
    end

    it 'increments and expires version keys in one Redis transaction' do
      key = described_class.conversation_version_key(account_id)
      connection = instance_double(Redis)
      transaction = instance_double(Redis::MultiConnection)

      allow(Redis::Alfred).to receive(:with).and_yield(connection)
      expect(connection).to receive(:multi).and_yield(transaction).and_return([1, true])
      expect(transaction).to receive(:incr).with(key)
      expect(transaction).to receive(:expire).with(key, Conversations::UnreadCounts::FILTERED_COUNT_VERSION_TTL)

      expect(described_class.bump_conversation_version!(account_id)).to eq(1)
    end

    it 'expires version keys after bumping them' do
      described_class.bump_conversation_version!(account_id)
      described_class.bump_built_in_filter_version!(account_id: account_id, user_id: user_id)
      described_class.bump_folder_index_version!(account_id: account_id, user_id: user_id)
      described_class.bump_filter_version!(account_id: account_id, filter_id: filter_id)

      version_keys.each do |key|
        expect(ttl_for(key)).to be_within(5).of(Conversations::UnreadCounts::FILTERED_COUNT_VERSION_TTL)
      end
    end
  end

  describe 'built-in filter count snapshots' do
    it 'round-trips counts and classifies fresh, stale, expired, and missing snapshots' do
      account_version = described_class.bump_conversation_version!(account_id)
      built_in_filter_version = described_class.bump_built_in_filter_version!(account_id: account_id, user_id: user_id)

      described_class.write_built_in_filter_counts!(
        account_id: account_id,
        user_id: user_id,
        account_version: account_version,
        built_in_filter_version: built_in_filter_version,
        built_at: built_at,
        counts: { mentions_count: 3, participating_count: 4, unattended_count: 5 },
        meta: { permission_mode: 'base' }
      )

      snapshot = described_class.built_in_filter_counts(account_id: account_id, user_id: user_id)
      expect(snapshot[:counts]).to eq(mentions_count: 3, participating_count: 4, unattended_count: 5)
      expect(snapshot[:meta]).to eq(permission_mode: 'base')
      expect(ttl_for(described_class.built_in_filter_counts_key(account_id, user_id))).to be_within(5).of(
        Conversations::UnreadCounts::FILTERED_COUNT_REDIS_TTL
      )

      expect(described_class.built_in_filter_counts_state(account_id: account_id, user_id: user_id, now: built_at + 1.minute)).to be_fresh

      described_class.bump_built_in_filter_version!(account_id: account_id, user_id: user_id)
      expect(described_class.built_in_filter_counts_state(account_id: account_id, user_id: user_id, now: built_at + 2.minutes)).to be_stale
      expect(described_class.built_in_filter_counts_state(account_id: account_id, user_id: user_id, now: built_at + 36.minutes)).to be_expired

      Redis::Alfred.delete(described_class.built_in_filter_counts_key(account_id, user_id))
      expect(described_class.built_in_filter_counts_state(account_id: account_id, user_id: user_id)).to be_missing
    end
  end

  describe 'folder index snapshots' do
    it 'round-trips folder ids and classifies freshness against the folder index version' do
      folder_index_version = described_class.bump_folder_index_version!(account_id: account_id, user_id: user_id)

      described_class.write_folder_index!(
        account_id: account_id,
        user_id: user_id,
        folder_index_version: folder_index_version,
        built_at: built_at,
        filter_ids: %w[10 11]
      )

      expect(described_class.folder_index(account_id: account_id, user_id: user_id)[:filter_ids]).to eq([10, 11])
      expect(described_class.folder_index_state(account_id: account_id, user_id: user_id, now: built_at + 1.minute)).to be_fresh

      described_class.bump_folder_index_version!(account_id: account_id, user_id: user_id)
      expect(described_class.folder_index_state(account_id: account_id, user_id: user_id, now: built_at + 2.minutes)).to be_stale
    end
  end

  describe 'saved filter count snapshots' do
    it 'round-trips counts and uses account, filter, and owner built-in filter versions for freshness' do
      account_version = described_class.bump_conversation_version!(account_id)
      filter_version = described_class.bump_filter_version!(account_id: account_id, filter_id: filter_id)
      owner_built_in_filter_version = described_class.bump_built_in_filter_version!(account_id: account_id, user_id: user_id)

      described_class.write_filter_count!(
        account_id: account_id,
        filter_id: filter_id,
        user_id: user_id,
        count: 7,
        account_version: account_version,
        filter_version: filter_version,
        owner_built_in_filter_version: owner_built_in_filter_version,
        built_at: built_at,
        meta: { status: 'ok', timed_out: false, invalid_filter: false }
      )

      snapshot = described_class.filter_count(account_id: account_id, filter_id: filter_id)
      expect(snapshot[:count]).to eq(7)
      expect(snapshot[:meta]).to eq(status: 'ok', timed_out: false, invalid_filter: false)
      expect(described_class.filter_count_state(account_id: account_id, filter_id: filter_id, now: built_at + 1.minute)).to be_fresh

      described_class.bump_filter_version!(account_id: account_id, filter_id: filter_id)
      expect(described_class.filter_count_state(account_id: account_id, filter_id: filter_id, now: built_at + 2.minutes)).to be_stale

      described_class.delete_filter_count!(account_id: account_id, filter_id: filter_id)
      expect(described_class.filter_count(account_id: account_id, filter_id: filter_id)).to be_nil
    end

    it 'uses caller-provided versions when classifying snapshots' do
      account_version = described_class.bump_conversation_version!(account_id)
      filter_version = described_class.bump_filter_version!(account_id: account_id, filter_id: filter_id)
      owner_built_in_filter_version = described_class.bump_built_in_filter_version!(account_id: account_id, user_id: user_id)

      described_class.write_filter_count!(
        account_id: account_id,
        filter_id: filter_id,
        user_id: user_id,
        count: 7,
        account_version: account_version,
        filter_version: filter_version,
        owner_built_in_filter_version: owner_built_in_filter_version,
        built_at: built_at
      )

      versions = {
        account_version: account_version,
        filter_version: filter_version,
        owner_built_in_filter_version: owner_built_in_filter_version
      }

      expect(described_class).not_to receive(:conversation_version)
      expect(described_class).not_to receive(:filter_version)
      expect(described_class).not_to receive(:built_in_filter_version)

      expect(
        described_class.filter_count_state(
          account_id: account_id,
          filter_id: filter_id,
          versions: versions,
          now: built_at + 1.minute
        )
      ).to be_fresh
    end
  end

  describe 'refresh throttles' do
    it 'uses refresh_after and independent throttle keys to suppress duplicate rebuilds' do
      described_class.write_built_in_filter_counts!(
        account_id: account_id,
        user_id: user_id,
        account_version: 0,
        built_in_filter_version: 0,
        built_at: built_at,
        counts: {}
      )

      snapshot = described_class.built_in_filter_counts(account_id: account_id, user_id: user_id)
      expect(described_class.refresh_due?(snapshot, now: built_at + 10.seconds)).to be(false)
      expect(described_class.refresh_due?(snapshot, now: built_at + 31.seconds)).to be(true)

      expect(described_class.claim_built_in_filter_refresh!(account_id: account_id, user_id: user_id)).to be(true)
      expect(described_class.claim_built_in_filter_refresh!(account_id: account_id, user_id: user_id)).to be(false)
      expect(described_class.claim_folder_index_refresh!(account_id: account_id, user_id: user_id)).to be(true)
      expect(described_class.claim_filter_refresh!(account_id: account_id, filter_id: filter_id)).to be(true)
    end
  end

  describe 'Redis access pattern' do
    it 'does not scan Redis keys' do
      expect(Redis::Alfred).not_to receive(:scan_each)

      described_class.bump_conversation_version!(account_id)
      described_class.write_folder_index!(account_id: account_id, user_id: user_id, folder_index_version: 0, filter_ids: [filter_id])
      described_class.folder_index_state(account_id: account_id, user_id: user_id)
      described_class.claim_filter_refresh!(account_id: account_id, filter_id: filter_id)
      described_class.delete_filter_count!(account_id: account_id, filter_id: filter_id)
    end
  end

  def ttl_for(key)
    Redis::Alfred.ttl(key)
  end

  def redis_keys
    version_keys + snapshot_keys + lock_and_throttle_keys
  end

  def version_keys
    [
      described_class.conversation_version_key(account_id),
      described_class.built_in_filter_version_key(account_id, user_id),
      described_class.folder_index_version_key(account_id, user_id),
      described_class.filter_version_key(account_id, filter_id)
    ]
  end

  def snapshot_keys
    [
      described_class.built_in_filter_counts_key(account_id, user_id),
      described_class.folder_index_key(account_id, user_id),
      described_class.filter_count_key(account_id, filter_id)
    ]
  end

  def lock_and_throttle_keys
    [
      described_class.built_in_filter_build_lock_key(account_id, user_id),
      described_class.built_in_filter_refresh_throttle_key(account_id, user_id),
      described_class.folder_index_build_lock_key(account_id, user_id),
      described_class.folder_index_refresh_throttle_key(account_id, user_id),
      described_class.filter_build_lock_key(account_id, filter_id),
      described_class.filter_refresh_throttle_key(account_id, filter_id)
    ]
  end
end
