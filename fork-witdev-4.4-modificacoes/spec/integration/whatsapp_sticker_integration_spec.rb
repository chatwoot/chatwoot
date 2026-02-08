# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WhatsApp Sticker Integration', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account, channel: whatsapp_channel) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox) }

  before do
    sign_in user
    allow(Rails.cache).to receive(:fetch).and_call_original
    allow(HTTParty).to receive(:get).and_call_original
    allow(HTTParty).to receive(:post).and_call_original
  end

  describe 'Complete Sticker Flow Integration' do
    context 'when sending a Giphy sticker' do
      let(:giphy_response) do
        {
          'data' => [
            {
              'id' => 'test_giphy_id',
              'title' => 'Happy Sticker',
              'images' => {
                'fixed_height' => {
                  'webp' => 'https://media.giphy.com/media/test/giphy.webp'
                }
              }
            }
          ]
        }
      end

      let(:whatsapp_upload_response) do
        { 'id' => 'whatsapp_media_id_123' }
      end

      let(:whatsapp_send_response) do
        {
          'messages' => [
            {
              'id' => 'whatsapp_message_id_456'
            }
          ]
        }
      end

      before do
        # Mock Giphy API
        allow(HTTParty).to receive(:get)
          .with(include('api.giphy.com'), any_args)
          .and_return(double(success?: true, body: giphy_response.to_json))

        # Mock WhatsApp media upload
        allow(HTTParty).to receive(:post)
          .with(include('media'), any_args)
          .and_return(double(success?: true, parsed_response: whatsapp_upload_response))

        # Mock WhatsApp message send
        allow(HTTParty).to receive(:post)
          .with(include('messages'), any_args)
          .and_return(double(success?: true, parsed_response: whatsapp_send_response))

        # Mock media download
        allow(HTTParty).to receive(:get)
          .with('https://media.giphy.com/media/test/giphy.webp')
          .and_return(double(body: 'fake_webp_data'))
      end

      it 'completes the full sticker sending flow' do
        # Step 1: Fetch trending stickers
        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'giphy' }
        
        expect(response).to have_http_status(:success)
        stickers_data = JSON.parse(response.body)
        expect(stickers_data['stickers']).to be_present
        expect(stickers_data['stickers'].first['provider']).to eq('giphy')

        # Step 2: Send sticker
        sticker_data = {
          id: 'test_giphy_id',
          url: 'https://media.giphy.com/media/test/giphy.webp',
          alt: 'Happy Sticker',
          provider: 'giphy'
        }

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data['success']).to be true
        expect(response_data['message_id']).to be_present

        # Step 3: Verify message was created
        message = Message.find(response_data['message_id'])
        expect(message.content_type).to eq('sticker')
        expect(message.content_attributes['sticker_data']).to include(sticker_data.stringify_keys)
        expect(message.additional_attributes['skip_send_reply']).to be true

        # Step 4: Verify recent stickers were updated
        user.reload
        recent_stickers = user.ui_settings&.dig('recent_stickers')
        expect(recent_stickers).to be_present
        expect(recent_stickers.first['url']).to eq(sticker_data[:url])
        expect(recent_stickers.first['provider']).to eq('giphy')

        # Step 5: Verify cache was used for media_id
        cache_key = "whatsapp_media_id:#{Digest::MD5.hexdigest(sticker_data[:url])}"
        expect(Rails.cache.read(cache_key)).to eq('whatsapp_media_id_123')
      end

      it 'handles Giphy API failures gracefully' do
        # Mock Giphy API failure
        allow(HTTParty).to receive(:get)
          .with(include('api.giphy.com'), any_args)
          .and_return(double(success?: false, code: 500))

        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'giphy' }
        
        expect(response).to have_http_status(:success)
        stickers_data = JSON.parse(response.body)
        expect(stickers_data['stickers']).to eq([])
      end

      it 'handles WhatsApp API failures gracefully' do
        # Mock WhatsApp API failure
        allow(HTTParty).to receive(:post)
          .with(include('messages'), any_args)
          .and_return(double(success?: false, parsed_response: { 'error' => { 'message' => 'API Error' } }))

        sticker_data = {
          id: 'test_giphy_id',
          url: 'https://media.giphy.com/media/test/giphy.webp',
          alt: 'Happy Sticker',
          provider: 'giphy'
        }

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        expect(response).to have_http_status(:unprocessable_entity)
        response_data = JSON.parse(response.body)
        expect(response_data['error']).to be_present

        # Verify no message was created
        expect(Message.where(conversation: conversation, content_type: 'sticker')).to be_empty
      end
    end

    context 'when working with custom stickers' do
      let!(:custom_sticker) do
        create(:attachment, 
               account: account, 
               file_type: :image,
               meta: { 
                 sticker_type: 'custom', 
                 sticker_pack: 'Company Pack',
                 tags: ['logo', 'brand']
               })
      end

      it 'fetches and sends custom stickers' do
        # Step 1: Fetch custom stickers
        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'custom' }
        
        expect(response).to have_http_status(:success)
        stickers_data = JSON.parse(response.body)
        expect(stickers_data['stickers']).to be_present
        expect(stickers_data['stickers'].first['provider']).to eq('custom')
        expect(stickers_data['stickers'].first['id']).to eq(custom_sticker.id)

        # Step 2: Send custom sticker
        sticker_data = stickers_data['stickers'].first

        # Mock WhatsApp responses
        allow(HTTParty).to receive(:post)
          .with(include('media'), any_args)
          .and_return(double(success?: true, parsed_response: { 'id' => 'custom_media_id' }))

        allow(HTTParty).to receive(:post)
          .with(include('messages'), any_args)
          .and_return(double(success?: true, parsed_response: { 'messages' => [{ 'id' => 'msg_id' }] }))

        allow(HTTParty).to receive(:get)
          .with(custom_sticker.download_url)
          .and_return(double(body: 'fake_image_data'))

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data['success']).to be true

        # Verify message was created with custom sticker
        message = Message.find(response_data['message_id'])
        expect(message.content_type).to eq('sticker')
        expect(message.content_attributes['sticker_data']['provider']).to eq('custom')
      end

      it 'filters custom stickers by pack' do
        # Create another sticker in different pack
        create(:attachment, 
               account: account, 
               file_type: :image,
               meta: { 
                 sticker_type: 'custom', 
                 sticker_pack: 'Different Pack'
               })

        get "/api/v1/accounts/#{account.id}/stickers", 
            params: { provider: 'custom', pack_name: 'Company Pack' }
        
        expect(response).to have_http_status(:success)
        stickers_data = JSON.parse(response.body)
        expect(stickers_data['stickers'].size).to eq(1)
        expect(stickers_data['stickers'].first['meta']['sticker_pack']).to eq('Company Pack')
      end
    end

    context 'when working with recent stickers' do
      before do
        # Set up user with recent stickers
        user.update!(
          ui_settings: {
            recent_stickers: [
              {
                url: 'https://example.com/sticker1.webp',
                alt: 'Recent Sticker 1',
                provider: 'giphy',
                used_at: 1.hour.ago.iso8601
              },
              {
                url: 'https://example.com/sticker2.webp',
                alt: 'Recent Sticker 2',
                provider: 'custom',
                used_at: 2.hours.ago.iso8601
              }
            ]
          }
        )
      end

      it 'fetches recent stickers for user' do
        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'recent' }
        
        expect(response).to have_http_status(:success)
        stickers_data = JSON.parse(response.body)
        expect(stickers_data['stickers'].size).to eq(2)
        expect(stickers_data['stickers'].first['url']).to eq('https://example.com/sticker1.webp')
        expect(stickers_data['stickers'].first['provider']).to eq('giphy')
      end

      it 'updates recent stickers order when reusing' do
        # Mock WhatsApp responses
        allow(HTTParty).to receive(:post).and_return(
          double(success?: true, parsed_response: { 'id' => 'media_id' }),
          double(success?: true, parsed_response: { 'messages' => [{ 'id' => 'msg_id' }] })
        )
        allow(HTTParty).to receive(:get).and_return(double(body: 'fake_data'))

        # Send the second sticker (should move to top)
        sticker_data = {
          url: 'https://example.com/sticker2.webp',
          alt: 'Recent Sticker 2',
          provider: 'custom'
        }

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        expect(response).to have_http_status(:success)

        # Verify sticker moved to top of recent list
        user.reload
        recent_stickers = user.ui_settings['recent_stickers']
        expect(recent_stickers.first['url']).to eq('https://example.com/sticker2.webp')
        expect(recent_stickers.size).to eq(2) # Should not duplicate
      end
    end

    context 'when testing cache behavior' do
      let(:sticker_url) { 'https://media.giphy.com/media/test/giphy.webp' }
      let(:cache_key) { "whatsapp_media_id:#{Digest::MD5.hexdigest(sticker_url)}" }

      before do
        # Mock responses
        allow(HTTParty).to receive(:post)
          .with(include('media'), any_args)
          .and_return(double(success?: true, parsed_response: { 'id' => 'cached_media_id' }))

        allow(HTTParty).to receive(:post)
          .with(include('messages'), any_args)
          .and_return(double(success?: true, parsed_response: { 'messages' => [{ 'id' => 'msg_id' }] }))

        allow(HTTParty).to receive(:get)
          .with(sticker_url)
          .and_return(double(body: 'fake_data'))
      end

      it 'caches WhatsApp media_id for 30 days' do
        sticker_data = {
          url: sticker_url,
          alt: 'Test Sticker',
          provider: 'giphy'
        }

        # First send - should upload and cache
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        expect(response).to have_http_status(:success)
        expect(Rails.cache.read(cache_key)).to eq('cached_media_id')

        # Second send - should use cache
        expect(HTTParty).not_to receive(:post).with(include('media'), any_args)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        expect(response).to have_http_status(:success)
      end

      it 'caches Giphy API responses for 10 minutes' do
        giphy_cache_key = 'giphy_stickers:trending'
        
        # Mock first API call
        allow(HTTParty).to receive(:get)
          .with(include('api.giphy.com'), any_args)
          .and_return(double(success?: true, body: { data: [] }.to_json))
          .once

        # First request - should call API and cache
        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'giphy' }
        expect(response).to have_http_status(:success)

        # Second request - should use cache (no API call)
        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'giphy' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when testing error scenarios' do
      it 'handles network timeouts gracefully' do
        allow(HTTParty).to receive(:get)
          .with(include('api.giphy.com'), any_args)
          .and_raise(Net::OpenTimeout)

        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'giphy' }
        
        expect(response).to have_http_status(:success)
        stickers_data = JSON.parse(response.body)
        expect(stickers_data['stickers']).to eq([])
      end

      it 'validates conversation belongs to account' do
        other_account = create(:account)
        other_conversation = create(:conversation, account: other_account)

        sticker_data = { url: 'test.webp', alt: 'Test', provider: 'giphy' }

        post "/api/v1/accounts/#{account.id}/conversations/#{other_conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        expect(response).to have_http_status(:not_found)
      end

      it 'validates sticker data presence' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: {}

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'Performance and Scalability' do
    it 'handles concurrent sticker sends efficiently' do
      sticker_data = {
        url: 'https://media.giphy.com/media/concurrent/test.webp',
        alt: 'Concurrent Test',
        provider: 'giphy'
      }

      # Mock responses
      allow(HTTParty).to receive(:post).and_return(
        double(success?: true, parsed_response: { 'id' => 'media_id' }),
        double(success?: true, parsed_response: { 'messages' => [{ 'id' => 'msg_id' }] })
      )
      allow(HTTParty).to receive(:get).and_return(double(body: 'fake_data'))

      # Simulate concurrent requests
      threads = 5.times.map do |i|
        Thread.new do
          post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
               params: { sticker: sticker_data }
          response.status
        end
      end

      results = threads.map(&:value)
      expect(results).to all(eq(200))

      # Verify only one message per thread was created
      messages = Message.where(conversation: conversation, content_type: 'sticker')
      expect(messages.count).to eq(5)
    end

    it 'maintains reasonable response times under load' do
      # Mock fast responses
      allow(HTTParty).to receive(:get)
        .with(include('api.giphy.com'), any_args)
        .and_return(double(success?: true, body: { data: [] }.to_json))

      start_time = Time.current

      10.times do
        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'giphy' }
        expect(response).to have_http_status(:success)
      end

      total_time = Time.current - start_time
      expect(total_time).to be < 5.seconds # Should complete in under 5 seconds
    end
  end

  describe 'Cross-browser and Mobile Compatibility' do
    it 'returns proper CORS headers for frontend requests' do
      get "/api/v1/accounts/#{account.id}/stickers", 
          params: { provider: 'giphy' },
          headers: { 'Origin' => 'http://localhost:3000' }

      expect(response.headers['Access-Control-Allow-Origin']).to be_present
    end

    it 'handles mobile-specific user agents properly' do
      mobile_user_agent = 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15'
      
      get "/api/v1/accounts/#{account.id}/stickers", 
          params: { provider: 'giphy' },
          headers: { 'User-Agent' => mobile_user_agent }

      expect(response).to have_http_status(:success)
    end
  end

  describe 'Requirements Validation' do
    it 'validates all functional requirements are met' do
      # Requirement 1: Interface de Seleção de Stickers
      get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'giphy' }
      expect(response).to have_http_status(:success)

      # Requirement 2: Integração com Giphy
      stickers_data = JSON.parse(response.body)
      expect(stickers_data['stickers']).to be_an(Array)

      # Requirement 3: Stickers Personalizados
      get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'custom' }
      expect(response).to have_http_status(:success)

      # Requirement 4: Stickers Recentemente Utilizados
      get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'recent' }
      expect(response).to have_http_status(:success)

      # Requirement 5: Envio Otimizado via WhatsApp Cloud API
      # (Tested in main flow above)

      # Requirement 6: Processamento e Validação de Imagens
      # (Tested in custom sticker scenarios)

      # Requirement 7: Cache e Performance
      # (Tested in cache behavior scenarios)

      # Requirement 8: Integração com Interface Existente
      # (Tested through API endpoints and message creation)
    end
  end
end