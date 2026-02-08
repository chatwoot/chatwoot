require 'rails_helper'

RSpec.describe Whatsapp::SendStickerService, type: :service do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false) }
  let(:inbox) { whatsapp_channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:contact_inbox) { conversation.contact_inbox }
  
  let(:sticker_data) do
    {
      url: 'https://example.com/sticker.webp',
      alt: 'Test Sticker',
      provider: 'giphy',
      id: 'test123'
    }
  end

  let(:service) do
    described_class.new(
      conversation: conversation,
      sticker_data: sticker_data,
      user: user
    )
  end

  let(:provider_service) { instance_double('Whatsapp::Providers::WhatsappCloudService') }
  let(:media_id) { 'media_123456' }

  before do
    allow(whatsapp_channel).to receive(:provider_service).and_return(provider_service)
    allow(HTTParty).to receive(:get).and_return(double(body: 'fake_image_data'))
  end

  describe '#perform' do
    context 'when successful' do
      before do
        allow(provider_service).to receive(:upload_media).and_return(media_id)
        allow(provider_service).to receive(:send_sticker_message).and_return({ success: true })
      end

      it 'creates a sticker message immediately with optimistic flow' do
        expect { service.perform }.to change(Message, :count).by(1)
        
        message = Message.last
        expect(message.content_type).to eq('sticker')
        expect(message.content).to eq('Sticker: Test Sticker')
        expect(message.content_attributes['sticker_data']).to eq(sticker_data.stringify_keys)
        expect(message.additional_attributes['skip_send_reply']).to be true
        expect(message.message_type).to eq('outgoing')
        expect(message.status).to eq('delivered') # Should be delivered after success
      end

      it 'uploads media to WhatsApp and sends sticker message with optimistic flow' do
        expect(provider_service).to receive(:upload_media).and_return(media_id)
        expect(provider_service).to receive(:send_sticker_message).with(contact_inbox.source_id, media_id).and_return('whatsapp_msg_123')
        
        result = service.perform
        expect(result[:success]).to be true
        expect(result[:message_id]).to be_present
        expect(result[:source_id]).to eq('whatsapp_msg_123')
        
        # Verify message status progression
        message = Message.find(result[:message_id])
        expect(message.status).to eq('delivered')
        expect(message.source_id).to eq('whatsapp_msg_123')
      end

      it 'records sticker in user recent stickers' do
        service.perform
        
        user.reload
        recent_stickers = user.ui_settings['recent_stickers']
        
        expect(recent_stickers).to be_present
        expect(recent_stickers.first['url']).to eq(sticker_data[:url])
        expect(recent_stickers.first['alt']).to eq(sticker_data[:alt])
        expect(recent_stickers.first['provider']).to eq(sticker_data[:provider])
        expect(recent_stickers.first['used_at']).to be_present
      end

      it 'returns success with message_id' do
        result = service.perform
        
        expect(result[:success]).to be true
        expect(result[:message_id]).to eq(Message.last.id)
      end
    end

    context 'when media upload fails' do
      before do
        allow(provider_service).to receive(:upload_media).and_return(nil)
      end

      it 'creates message optimistically but updates to failed status' do
        expect { service.perform }.to change(Message, :count).by(1)
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('MEDIA_UPLOAD_FAILED')
        
        # Verify message was created but marked as failed
        message = Message.last
        expect(message.status).to eq('failed')
        expect(message.content_type).to eq('sticker')
      end
    end

    context 'when WhatsApp sending fails' do
      before do
        allow(provider_service).to receive(:upload_media).and_return(media_id)
        allow(provider_service).to receive(:send_sticker_message).and_return({ 
          success: false, 
          error: 'WhatsApp API error' 
        })
      end

      it 'creates message optimistically but updates to failed status' do
        expect { service.perform }.to change(Message, :count).by(1)
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error]).to eq('WhatsApp API error')
        
        # Verify message was created but marked as failed
        message = Message.last
        expect(message.status).to eq('failed')
        expect(message.content_type).to eq('sticker')
      end
    end
  end

  describe 'caching behavior' do
    before do
      Redis::Alfred.flushall
      allow(provider_service).to receive(:send_sticker_message).and_return('whatsapp_msg_123')
    end

    context 'when media_id is not cached' do
      it 'uploads media and caches the result with proper TTL' do
        expect(provider_service).to receive(:upload_media).once.and_return(media_id)
        expect(Redis::Alfred).to receive(:setex)
          .with(anything, media_id, described_class::MEDIA_CACHE_TTL)
        
        service.perform
      end
    end

    context 'when media_id is cached' do
      before do
        cache_key = service.send(:generate_media_cache_key, sticker_data[:url])
        Redis::Alfred.setex(cache_key, media_id, described_class::MEDIA_CACHE_TTL)
      end

      it 'uses cached media_id without uploading' do
        expect(provider_service).not_to receive(:upload_media)
        expect(provider_service).to receive(:send_sticker_message).with(contact_inbox.source_id, media_id)
        
        service.perform
      end
    end

    context 'cache key generation' do
      it 'generates consistent cache keys for same URL' do
        key1 = service.send(:generate_media_cache_key, sticker_data[:url])
        key2 = service.send(:generate_media_cache_key, sticker_data[:url])
        expect(key1).to eq(key2)
      end

      it 'includes channel ID in cache key' do
        cache_key = service.send(:generate_media_cache_key, sticker_data[:url])
        expect(cache_key).to include(whatsapp_channel.id.to_s)
      end

      it 'generates different keys for different URLs' do
        key1 = service.send(:generate_media_cache_key, 'https://example.com/sticker1.webp')
        key2 = service.send(:generate_media_cache_key, 'https://example.com/sticker2.webp')
        expect(key1).not_to eq(key2)
      end
    end

    context 'cache error handling' do
      it 'tracks cache errors' do
        allow(Rails.cache).to receive(:fetch).and_raise(StandardError.new('Cache error'))
        
        result = service.perform
        expect(result[:success]).to be false
        expect(Rails.cache.read('whatsapp_media_cache_error')).to eq(1)
      end
    end
  end

  describe '.invalidate_media_cache' do
    let(:test_url) { 'https://example.com/test.webp' }
    
    before do
      Redis::Alfred.flushall
    end

    context 'with specific channel ID' do
      it 'invalidates cache for specific channel' do
        url_hash = Digest::MD5.hexdigest(test_url)
        cache_key = format(Redis::RedisKeys::WHATSAPP_MEDIA_CACHE, channel_id: whatsapp_channel.id, url_hash: url_hash)
        Redis::Alfred.setex(cache_key, 'test_media_id', 1.hour)
        
        described_class.invalidate_media_cache(test_url, whatsapp_channel.id)
        expect(Redis::Alfred.get(cache_key)).to be_nil
      end
    end
  end

  describe 'recent stickers tracking' do
    let(:existing_sticker) do
      {
        'url' => 'https://example.com/old.webp',
        'alt' => 'Old Sticker',
        'provider' => 'custom',
        'used_at' => 1.hour.ago.iso8601
      }
    end

    before do
      allow(provider_service).to receive(:upload_media).and_return(media_id)
      allow(provider_service).to receive(:send_sticker_message).and_return({ success: true })
    end

    context 'when user has no recent stickers' do
      it 'creates new recent stickers list' do
        service.perform
        
        user.reload
        recent_stickers = user.ui_settings['recent_stickers']
        
        expect(recent_stickers.length).to eq(1)
        expect(recent_stickers.first['url']).to eq(sticker_data[:url])
      end
    end

    context 'when user has existing recent stickers' do
      before do
        user.update_column(:ui_settings, { 'recent_stickers' => [existing_sticker] })
      end

      it 'adds new sticker to beginning of list' do
        service.perform
        
        user.reload
        recent_stickers = user.ui_settings['recent_stickers']
        
        expect(recent_stickers.length).to eq(2)
        expect(recent_stickers.first['url']).to eq(sticker_data[:url])
        expect(recent_stickers.last['url']).to eq(existing_sticker['url'])
      end
    end

    context 'when sticker already exists in recent list' do
      before do
        existing_same_sticker = sticker_data.merge(used_at: 1.hour.ago.iso8601).stringify_keys
        user.update_column(:ui_settings, { 'recent_stickers' => [existing_sticker, existing_same_sticker] })
      end

      it 'moves existing sticker to top and updates timestamp' do
        service.perform
        
        user.reload
        recent_stickers = user.ui_settings['recent_stickers']
        
        expect(recent_stickers.length).to eq(2)
        expect(recent_stickers.first['url']).to eq(sticker_data[:url])
        expect(recent_stickers.first['used_at']).to be > 1.hour.ago.iso8601
        expect(recent_stickers.last['url']).to eq(existing_sticker['url'])
      end
    end

    context 'when user has more than 20 recent stickers' do
      before do
        many_stickers = (1..21).map do |i|
          {
            'url' => "https://example.com/sticker#{i}.webp",
            'alt' => "Sticker #{i}",
            'provider' => 'giphy',
            'used_at' => i.hours.ago.iso8601
          }
        end
        user.update_column(:ui_settings, { 'recent_stickers' => many_stickers })
      end

      it 'keeps only 20 most recent stickers' do
        service.perform
        
        user.reload
        recent_stickers = user.ui_settings['recent_stickers']
        
        expect(recent_stickers.length).to eq(20)
        expect(recent_stickers.first['url']).to eq(sticker_data[:url])
      end
    end

    context 'when user has no ui_settings' do
      before do
        user.update_column(:ui_settings, nil)
      end

      it 'initializes ui_settings and adds recent sticker' do
        service.perform
        
        user.reload
        expect(user.ui_settings).to be_present
        expect(user.ui_settings['recent_stickers']).to be_present
        expect(user.ui_settings['recent_stickers'].first['url']).to eq(sticker_data[:url])
      end
    end
  end

  describe 'error handling' do
    context 'validation errors' do
      it 'raises ConversationNotFoundError when conversation is nil' do
        service = described_class.new(conversation: nil, sticker_data: sticker_data, user: user)
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('CONVERSATION_NOT_FOUND')
        expect(result[:user_message]).to eq('Conversation not found or not accessible')
      end

      it 'raises InvalidStickerDataError when sticker_data is nil' do
        service = described_class.new(conversation: conversation, sticker_data: nil, user: user)
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('INVALID_STICKER_DATA')
      end

      it 'raises InvalidStickerDataError when sticker URL is missing' do
        invalid_data = sticker_data.merge(url: nil)
        service = described_class.new(conversation: conversation, sticker_data: invalid_data, user: user)
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('INVALID_STICKER_DATA')
      end

      it 'raises InvalidStickerDataError when user is nil' do
        service = described_class.new(conversation: conversation, sticker_data: sticker_data, user: nil)
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('INVALID_STICKER_DATA')
      end

      it 'raises InvalidStickerDataError for non-WhatsApp conversations' do
        email_channel = create(:channel_email, account: account)
        email_conversation = create(:conversation, account: account, inbox: email_channel.inbox)
        service = described_class.new(conversation: email_conversation, sticker_data: sticker_data, user: user)
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('INVALID_STICKER_DATA')
        expect(result[:user_message]).to include('WhatsApp conversations')
      end

      it 'raises InvalidStickerDataError for invalid URL format' do
        invalid_data = sticker_data.merge(url: 'not-a-url')
        service = described_class.new(conversation: conversation, sticker_data: invalid_data, user: user)
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('INVALID_STICKER_DATA')
        expect(result[:user_message]).to include('Invalid sticker data')
      end
    end

    context 'media upload errors' do
      it 'handles download timeout errors' do
        allow(HTTParty).to receive(:get).and_raise(Net::OpenTimeout.new('Request timeout'))
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('MEDIA_UPLOAD_FAILED')
        expect(result[:user_message]).to eq('Failed to upload sticker. Please try again.')
      end

      it 'handles download connection errors' do
        allow(HTTParty).to receive(:get).and_raise(SocketError.new('Connection failed'))
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('MEDIA_UPLOAD_FAILED')
      end

      it 'handles HTTP errors during download' do
        allow(HTTParty).to receive(:get).and_return(double(success?: false, code: 404))
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('MEDIA_UPLOAD_FAILED')
      end

      it 'handles file size validation errors' do
        large_file_data = 'x' * (600.kilobytes)
        allow(HTTParty).to receive(:get).and_return(double(success?: true, body: large_file_data))
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('MEDIA_UPLOAD_FAILED')
        expect(result[:user_message]).to include('Failed to upload sticker')
      end

      it 'handles small file validation errors' do
        small_file_data = 'x' * 50
        allow(HTTParty).to receive(:get).and_return(double(success?: true, body: small_file_data))
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('MEDIA_UPLOAD_FAILED')
      end

      it 'handles WhatsApp upload failures' do
        allow(HTTParty).to receive(:get).and_return(double(success?: true, body: 'valid_data'))
        allow(provider_service).to receive(:upload_media).and_return(nil)
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('MEDIA_UPLOAD_FAILED')
      end
    end

    context 'WhatsApp API errors' do
      before do
        allow(provider_service).to receive(:upload_media).and_return(media_id)
      end

      it 'handles rate limit errors' do
        allow(provider_service).to receive(:send_sticker_message).and_return({
          success: false,
          error: 'Rate limit exceeded'
        })
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('WHATSAPP_RATE_LIMIT')
        expect(result[:user_message]).to eq('Too many messages sent. Please wait a moment before sending another sticker.')
      end

      it 'handles invalid media errors' do
        allow(provider_service).to receive(:send_sticker_message).and_return({
          success: false,
          error: 'Invalid media format'
        })
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('WHATSAPP_INVALID_MEDIA')
        expect(result[:user_message]).to eq('This sticker format is not supported. Please try a different sticker.')
      end

      it 'handles authentication errors' do
        allow(provider_service).to receive(:send_sticker_message).and_return({
          success: false,
          error: 'Authentication failed'
        })
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('WHATSAPP_AUTH_ERROR')
        expect(result[:user_message]).to eq('WhatsApp authentication error. Please contact your administrator.')
      end

      it 'handles quota exceeded errors' do
        allow(provider_service).to receive(:send_sticker_message).and_return({
          success: false,
          error: 'Quota exceeded'
        })
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('WHATSAPP_QUOTA_EXCEEDED')
        expect(result[:user_message]).to eq('WhatsApp message quota exceeded. Please try again later.')
      end

      it 'handles unknown WhatsApp errors' do
        allow(provider_service).to receive(:send_sticker_message).and_return({
          success: false,
          error: 'Unknown WhatsApp error'
        })
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('WHATSAPP_UNKNOWN_ERROR')
        expect(result[:user_message]).to eq('Unable to send sticker. Please try again.')
      end
    end

    context 'unexpected errors' do
      it 'handles unexpected exceptions gracefully' do
        allow(provider_service).to receive(:upload_media).and_raise(StandardError.new('Unexpected error'))
        
        result = service.perform
        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('UNKNOWN_ERROR')
        expect(result[:user_message]).to eq('An unexpected error occurred. Please try again.')
      end

      it 'logs unexpected errors with full backtrace' do
        error = StandardError.new('Unexpected error')
        allow(provider_service).to receive(:upload_media).and_raise(error)
        expect(Rails.logger).to receive(:error).with(/WhatsApp SendStickerService unexpected error.*Unexpected error/m)
        
        service.perform
      end
    end

    context 'optimistic message status updates' do
      before do
        allow(provider_service).to receive(:upload_media).and_return(media_id)
      end

      it 'updates message to failed status when WhatsApp sending fails' do
        allow(provider_service).to receive(:send_sticker_message).and_return({
          success: false,
          error: 'Send failed'
        })
        
        expect { service.perform }.to change(Message, :count).by(1)
        
        message = Message.last
        expect(message.status).to eq('failed')
        expect(message).to be_persisted
      end

      it 'updates message to delivered status when sending succeeds' do
        allow(provider_service).to receive(:send_sticker_message).and_return('whatsapp_msg_123')
        
        expect { service.perform }.to change(Message, :count).by(1)
        
        message = Message.last
        expect(message.status).to eq('delivered')
        expect(message.source_id).to eq('whatsapp_msg_123')
        expect(message).to be_persisted
      end
    end
  end
end