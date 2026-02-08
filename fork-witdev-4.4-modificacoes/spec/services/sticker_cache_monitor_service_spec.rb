require 'rails_helper'

RSpec.describe StickerCacheMonitorService, type: :service do
  before do
    Rails.cache.clear
  end

  describe '.get_cache_stats' do
    before do
      # Set up some mock cache metrics
      Rails.cache.write('giphy_cache_hit', 10)
      Rails.cache.write('giphy_cache_miss', 5)
      Rails.cache.write('giphy_cache_error', 1)
      
      Rails.cache.write('whatsapp_media_cache_hit', 20)
      Rails.cache.write('whatsapp_media_cache_miss', 8)
      Rails.cache.write('whatsapp_media_cache_error', 2)
      
      Rails.cache.write('sticker_service_cache_hit', 15)
      Rails.cache.write('sticker_service_cache_miss', 3)
      Rails.cache.write('sticker_service_cache_error', 0)
      Rails.cache.write('sticker_service_cache_packs_hit', 5)
      Rails.cache.write('sticker_service_cache_packs_miss', 2)
      Rails.cache.write('sticker_service_cache_packs_error', 0)
    end

    it 'returns comprehensive cache statistics' do
      stats = described_class.get_cache_stats

      expect(stats).to have_key(:giphy)
      expect(stats).to have_key(:whatsapp_media)
      expect(stats).to have_key(:custom_stickers)
      expect(stats).to have_key(:overall)
    end

    it 'calculates correct Giphy stats' do
      stats = described_class.get_cache_stats

      expect(stats[:giphy][:hits]).to eq(10)
      expect(stats[:giphy][:misses]).to eq(5)
      expect(stats[:giphy][:errors]).to eq(1)
      expect(stats[:giphy][:total_requests]).to eq(15)
      expect(stats[:giphy][:hit_rate]).to eq(0.667)
    end

    it 'calculates correct WhatsApp media stats' do
      stats = described_class.get_cache_stats

      expect(stats[:whatsapp_media][:hits]).to eq(20)
      expect(stats[:whatsapp_media][:misses]).to eq(8)
      expect(stats[:whatsapp_media][:errors]).to eq(2)
      expect(stats[:whatsapp_media][:total_requests]).to eq(28)
      expect(stats[:whatsapp_media][:hit_rate]).to eq(0.714)
    end

    it 'calculates correct custom stickers stats' do
      stats = described_class.get_cache_stats

      expect(stats[:custom_stickers][:stickers][:hits]).to eq(15)
      expect(stats[:custom_stickers][:stickers][:misses]).to eq(3)
      expect(stats[:custom_stickers][:stickers][:hit_rate]).to eq(0.833)
      
      expect(stats[:custom_stickers][:packs][:hits]).to eq(5)
      expect(stats[:custom_stickers][:packs][:misses]).to eq(2)
      expect(stats[:custom_stickers][:packs][:hit_rate]).to eq(0.714)
    end

    it 'calculates correct overall stats' do
      stats = described_class.get_cache_stats

      # Total hits: 10 + 20 + 15 + 5 = 50
      # Total requests: 15 + 28 + 18 + 7 = 68
      # Hit rate: 50/68 = 0.735
      expect(stats[:overall][:total_hits]).to eq(50)
      expect(stats[:overall][:total_requests]).to eq(68)
      expect(stats[:overall][:overall_hit_rate]).to eq(0.735)
    end

    context 'when no cache data exists' do
      before do
        Rails.cache.clear
      end

      it 'returns zero values' do
        stats = described_class.get_cache_stats

        expect(stats[:giphy][:hits]).to eq(0)
        expect(stats[:giphy][:hit_rate]).to eq(0)
        expect(stats[:overall][:overall_hit_rate]).to eq(0)
      end
    end
  end

  describe '.reset_cache_stats' do
    before do
      Rails.cache.write('giphy_cache_hit', 10)
      Rails.cache.write('whatsapp_media_cache_miss', 5)
      Rails.cache.write('sticker_service_cache_error', 2)
    end

    it 'clears all cache statistics' do
      expect(Rails.cache).to receive(:delete_matched).with('*_cache_hit')
      expect(Rails.cache).to receive(:delete_matched).with('*_cache_miss')
      expect(Rails.cache).to receive(:delete_matched).with('*_cache_error')
      expect(Rails.cache).to receive(:delete_matched).with('*_cache_packs_*')

      described_class.reset_cache_stats
    end
  end

  describe '.warm_all_caches' do
    let(:giphy_service) { instance_double(GiphyService) }

    before do
      allow(GiphyService).to receive(:new).and_return(giphy_service)
      allow(giphy_service).to receive(:warm_cache)
    end

    it 'warms Giphy cache' do
      expect(giphy_service).to receive(:warm_cache)

      described_class.warm_all_caches
    end

    it 'warms custom stickers cache for accounts with stickers' do
      account = create(:account)
      create(:attachment, 
             account: account, 
             file_type: :image, 
             meta: { 'sticker_type' => 'custom', 'sticker_pack' => 'Test' })

      sticker_service = instance_double(StickerService)
      allow(StickerService).to receive(:new).with(account).and_return(sticker_service)
      allow(sticker_service).to receive(:custom_sticker_packs).and_return([{ name: 'Test' }])
      allow(sticker_service).to receive(:custom_stickers).with('Test')
      allow(sticker_service).to receive(:custom_stickers).with(no_args)

      described_class.warm_all_caches

      expect(sticker_service).to have_received(:custom_sticker_packs)
      expect(sticker_service).to have_received(:custom_stickers).with('Test')
      expect(sticker_service).to have_received(:custom_stickers).with(no_args)
    end

    it 'handles errors gracefully during custom stickers warming' do
      account = create(:account)
      create(:attachment, 
             account: account, 
             file_type: :image, 
             meta: { 'sticker_type' => 'custom' })

      allow(StickerService).to receive(:new).and_raise(StandardError.new('Service error'))
      expect(Rails.logger).to receive(:error).with(/Error warming custom stickers cache/)

      expect { described_class.warm_all_caches }.not_to raise_error
    end
  end

  describe '.cache_health_check' do
    it 'returns health status with hit rate' do
      Rails.cache.write('giphy_cache_hit', 8)
      Rails.cache.write('giphy_cache_miss', 2)

      health = described_class.cache_health_check

      expect(health[:redis_available]).to be true
      expect(health[:cache_hit_rate]).to eq(0.8)
      expect(health[:timestamp]).to be_present
    end

    it 'logs warning for low hit rate' do
      Rails.cache.write('giphy_cache_hit', 1)
      Rails.cache.write('giphy_cache_miss', 9)

      expect(Rails.logger).to receive(:warn).with(/Low cache hit rate detected: 0.1/)

      described_class.cache_health_check
    end

    context 'when Redis is unavailable' do
      before do
        allow(Rails.cache).to receive(:write).and_raise(StandardError.new('Redis error'))
      end

      it 'returns redis_available as false' do
        health = described_class.cache_health_check

        expect(health[:redis_available]).to be false
      end
    end
  end

  describe 'private methods' do
    describe '.redis_available?' do
      it 'returns true when Redis is working' do
        expect(described_class.send(:redis_available?)).to be true
      end

      it 'returns false when Redis fails' do
        allow(Rails.cache).to receive(:write).and_raise(StandardError.new('Redis error'))

        expect(described_class.send(:redis_available?)).to be false
      end
    end

    describe '.calculate_overall_hit_rate' do
      before do
        Rails.cache.write('giphy_cache_hit', 5)
        Rails.cache.write('giphy_cache_miss', 5)
        Rails.cache.write('whatsapp_media_cache_hit', 10)
        Rails.cache.write('whatsapp_media_cache_miss', 0)
      end

      it 'calculates correct overall hit rate' do
        # Total hits: 5 + 10 = 15
        # Total requests: 10 + 10 = 20
        # Hit rate: 15/20 = 0.75
        hit_rate = described_class.send(:calculate_overall_hit_rate)

        expect(hit_rate).to eq(0.75)
      end
    end
  end
end