# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integrations::Socialwise::CacheManager do
  let(:account) { create(:account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
  let(:inbox) { create(:inbox, channel: whatsapp_channel, account: account) }

  before do
    # Clear any existing cache before each test
    described_class.clear_all_cache
  end

  after do
    # Clean up after each test
    described_class.clear_all_cache
  end

  describe '.channel_type' do
    context 'when cache is empty' do
      it 'executes the block and caches the result' do
        block_executed = false
        
        result = described_class.channel_type(inbox.id) do
          block_executed = true
          'Channel::Whatsapp'
        end
        
        expect(block_executed).to be true
        expect(result).to eq('Channel::Whatsapp')
      end
    end

    context 'when cache has the value' do
      before do
        # Pre-populate cache
        described_class.channel_type(inbox.id) { 'Channel::Whatsapp' }
      end

      it 'returns cached value without executing the block' do
        block_executed = false
        
        result = described_class.channel_type(inbox.id) do
          block_executed = true
          'Should not be called'
        end
        
        expect(block_executed).to be false
        expect(result).to eq('Channel::Whatsapp')
      end
    end
  end

  describe '.provider_config' do
    let(:provider_config) { { 'api_key' => 'test_key', 'phone_number_id' => '123' } }

    context 'when cache is empty' do
      it 'executes the block and caches the result' do
        block_executed = false
        
        result = described_class.provider_config(inbox.id) do
          block_executed = true
          provider_config
        end
        
        expect(block_executed).to be true
        expect(result).to eq(provider_config)
      end
    end

    context 'when cache has the value' do
      before do
        # Pre-populate cache
        described_class.provider_config(inbox.id) { provider_config }
      end

      it 'returns cached value without executing the block' do
        block_executed = false
        
        result = described_class.provider_config(inbox.id) do
          block_executed = true
          { 'should' => 'not_be_called' }
        end
        
        expect(block_executed).to be false
        expect(result).to eq(provider_config)
      end
    end
  end

  describe '.inbox_data' do
    let(:inbox_data) do
      {
        id: inbox.id,
        name: inbox.name,
        channel_type: 'Channel::Whatsapp',
        provider_config: { 'api_key' => 'test' }
      }
    end

    it 'caches and retrieves inbox data correctly' do
      # First call should execute block
      result1 = described_class.inbox_data(inbox.id) { inbox_data }
      expect(result1).to eq(inbox_data)

      # Second call should use cache
      block_executed = false
      result2 = described_class.inbox_data(inbox.id) do
        block_executed = true
        { different: 'data' }
      end

      expect(block_executed).to be false
      expect(result2).to eq(inbox_data)
    end
  end

  describe '.clear_inbox_cache' do
    before do
      # Populate cache with test data
      described_class.channel_type(inbox.id) { 'Channel::Whatsapp' }
      described_class.provider_config(inbox.id) { { 'api_key' => 'test' } }
      described_class.inbox_data(inbox.id) { { id: inbox.id } }
    end

    it 'clears all cache entries for the inbox' do
      deleted_count = described_class.clear_inbox_cache(inbox.id)
      expect(deleted_count).to be > 0

      # Verify cache is cleared by checking if blocks are executed
      block_executed = false
      described_class.channel_type(inbox.id) do
        block_executed = true
        'Channel::Whatsapp'
      end
      expect(block_executed).to be true
    end
  end

  describe '.preload_whatsapp_cache' do
    let!(:another_whatsapp_channel) { create(:channel_whatsapp, account: account) }
    let!(:another_inbox) { create(:inbox, channel: another_whatsapp_channel, account: account) }
    let!(:email_channel) { create(:channel_email, account: account) }
    let!(:email_inbox) { create(:inbox, channel: email_channel, account: account) }

    it 'preloads cache for all WhatsApp inboxes' do
      preloaded_count = described_class.preload_whatsapp_cache

      expect(preloaded_count).to eq(2) # Only WhatsApp inboxes

      # Verify cache is populated by checking no blocks are executed
      block_executed = false
      described_class.channel_type(inbox.id) do
        block_executed = true
        'Should not be called'
      end
      expect(block_executed).to be false
    end

    it 'preloads cache for WhatsApp inboxes of specific account' do
      other_account = create(:account)
      other_whatsapp_channel = create(:channel_whatsapp, account: other_account)
      other_inbox = create(:inbox, channel: other_whatsapp_channel, account: other_account)

      preloaded_count = described_class.preload_whatsapp_cache(account.id)

      expect(preloaded_count).to eq(2) # Only WhatsApp inboxes for the specific account
    end
  end

  describe '.cache_stats' do
    it 'returns empty stats when no cache operations have occurred' do
      stats = described_class.cache_stats
      expect(stats).to be_a(Hash)
      
      # All stats should be zero
      stats.each do |_cache_type, data|
        expect(data[:hits]).to eq(0)
        expect(data[:misses]).to eq(0)
        expect(data[:total]).to eq(0)
        expect(data[:hit_rate]).to eq(0)
      end
    end

    it 'tracks cache hits and misses correctly' do
      # Generate a cache miss
      described_class.channel_type(inbox.id) { 'Channel::Whatsapp' }
      
      # Generate a cache hit
      described_class.channel_type(inbox.id) { 'Should not be called' }
      
      stats = described_class.cache_stats
      channel_stats = stats['channel_type']
      
      expect(channel_stats[:hits]).to eq(1)
      expect(channel_stats[:misses]).to eq(1)
      expect(channel_stats[:total]).to eq(2)
      expect(channel_stats[:hit_rate]).to eq(50.0)
    end
  end

  describe '.health_check' do
    it 'returns healthy status when cache is working' do
      health = described_class.health_check
      
      expect(health[:status]).to eq('healthy')
      expect(health[:timestamp]).to be_present
      expect(health[:error]).to be_nil
    end
  end

  describe '.clear_all_cache' do
    before do
      # Populate cache with test data
      described_class.channel_type(inbox.id) { 'Channel::Whatsapp' }
      described_class.provider_config(inbox.id) { { 'api_key' => 'test' } }
    end

    it 'clears all SocialWise cache entries' do
      deleted_count = described_class.clear_all_cache
      expect(deleted_count).to be > 0

      # Verify all cache is cleared
      block_executed = false
      described_class.channel_type(inbox.id) do
        block_executed = true
        'Channel::Whatsapp'
      end
      expect(block_executed).to be true
    end
  end

  describe 'error handling' do
    context 'when Redis is unavailable' do
      before do
        allow(described_class).to receive(:redis_client).and_raise(Redis::CannotConnectError)
      end

      it 'still executes the block when cache fails' do
        block_executed = false
        
        result = described_class.channel_type(inbox.id) do
          block_executed = true
          'Channel::Whatsapp'
        end
        
        expect(block_executed).to be true
        expect(result).to eq('Channel::Whatsapp')
      end
    end

    context 'when block raises an error' do
      it 'does not cache the error result' do
        expect do
          described_class.channel_type(inbox.id) { raise StandardError, 'Test error' }
        end.to raise_error(StandardError, 'Test error')

        # Subsequent call should still execute the block
        block_executed = false
        result = described_class.channel_type(inbox.id) do
          block_executed = true
          'Channel::Whatsapp'
        end

        expect(block_executed).to be true
        expect(result).to eq('Channel::Whatsapp')
      end
    end
  end
end