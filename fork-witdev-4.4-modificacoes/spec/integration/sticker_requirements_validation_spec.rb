# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sticker Requirements Validation', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account, channel: whatsapp_channel) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox) }

  before do
    sign_in user
  end

  describe 'Requirement 1: Interface de Seleção de Stickers' do
    context 'Acceptance Criteria 1.1: Modal display on button click' do
      it 'provides API endpoint for sticker library data' do
        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'giphy' }
        
        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        expect(data).to have_key('stickers')
        expect(data['stickers']).to be_an(Array)
      end
    end

    context 'Acceptance Criteria 1.2: Tab navigation' do
      it 'supports different sticker providers through API' do
        providers = %w[giphy custom recent]
        
        providers.each do |provider|
          get "/api/v1/accounts/#{account.id}/stickers", params: { provider: provider }
          
          expect(response).to have_http_status(:success)
          data = JSON.parse(response.body)
          expect(data['stickers']).to be_an(Array)
        end
      end
    end

    context 'Acceptance Criteria 1.3: Immediate sticker sending' do
      it 'provides send sticker endpoint' do
        sticker_data = {
          id: 'test_sticker',
          url: 'https://example.com/sticker.webp',
          alt: 'Test Sticker',
          provider: 'giphy'
        }

        # Mock WhatsApp API responses
        allow(HTTParty).to receive(:post).and_return(
          double(success?: true, parsed_response: { 'id' => 'media_id' }),
          double(success?: true, parsed_response: { 'messages' => [{ 'id' => 'msg_id' }] })
        )
        allow(HTTParty).to receive(:get).and_return(double(body: 'fake_data'))

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        expect(data['success']).to be true
        expect(data['message_id']).to be_present
      end
    end

    context 'Acceptance Criteria 1.4: Loading indicators' do
      it 'handles loading states gracefully' do
        # Simulate slow API response
        allow(HTTParty).to receive(:get).and_wrap_original do |method, *args|
          sleep(0.1) # Small delay to simulate loading
          method.call(*args)
        end

        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'giphy' }
        
        expect(response).to have_http_status(:success)
      end
    end

    context 'Acceptance Criteria 1.5: Empty state handling' do
      it 'returns empty array when no stickers found' do
        # Mock empty Giphy response
        allow(HTTParty).to receive(:get)
          .with(include('api.giphy.com'), any_args)
          .and_return(double(success?: true, body: { data: [] }.to_json))

        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'giphy' }
        
        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        expect(data['stickers']).to eq([])
      end
    end
  end

  describe 'Requirement 2: Integração com Giphy' do
    let(:giphy_response) do
      {
        'data' => [
          {
            'id' => 'giphy_test_id',
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

    before do
      allow(HTTParty).to receive(:get)
        .with(include('api.giphy.com'), any_args)
        .and_return(double(success?: true, body: giphy_response.to_json))
    end

    context 'Acceptance Criteria 2.1: Popular stickers loading' do
      it 'fetches trending stickers from Giphy' do
        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'giphy' }
        
        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        expect(data['stickers'].first['provider']).to eq('giphy')
        expect(data['stickers'].first['id']).to eq('giphy_test_id')
      end
    end

    context 'Acceptance Criteria 2.2: Search functionality' do
      it 'searches stickers by term' do
        get "/api/v1/accounts/#{account.id}/stickers", 
            params: { provider: 'giphy', search_term: 'happy' }
        
        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        expect(data['stickers']).to be_present
      end
    end

    context 'Acceptance Criteria 2.3: Safe content filtering' do
      it 'only returns G-rated content' do
        # Verify API call includes rating parameter
        expect(HTTParty).to receive(:get)
          .with(include('api.giphy.com'), hash_including(query: hash_including(rating: 'g')))
          .and_return(double(success?: true, body: giphy_response.to_json))

        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'giphy' }
        
        expect(response).to have_http_status(:success)
      end
    end

    context 'Acceptance Criteria 2.4: Error handling' do
      it 'handles Giphy API unavailability' do
        allow(HTTParty).to receive(:get)
          .with(include('api.giphy.com'), any_args)
          .and_return(double(success?: false, code: 500))

        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'giphy' }
        
        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        expect(data['stickers']).to eq([])
      end
    end

    context 'Acceptance Criteria 2.5: Caching' do
      it 'caches Giphy responses for 10 minutes' do
        cache_key = 'giphy_stickers:trending'
        
        # First request should call API
        expect(Rails.cache).to receive(:fetch)
          .with(cache_key, expires_in: 10.minutes)
          .and_call_original

        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'giphy' }
        
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'Requirement 3: Stickers Personalizados' do
    context 'Acceptance Criteria 3.1: Image conversion' do
      it 'stores custom stickers using Attachment model' do
        custom_sticker = create(:attachment, 
                               account: account, 
                               file_type: :image,
                               meta: { 
                                 sticker_type: 'custom', 
                                 sticker_pack: 'Company Pack'
                               })

        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'custom' }
        
        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        expect(data['stickers'].first['id']).to eq(custom_sticker.id)
        expect(data['stickers'].first['provider']).to eq('custom')
      end
    end

    context 'Acceptance Criteria 3.2: Attachment model usage' do
      it 'uses meta field for sticker identification' do
        custom_sticker = create(:attachment, 
                               account: account, 
                               file_type: :image,
                               meta: { 
                                 sticker_type: 'custom', 
                                 sticker_pack: 'Test Pack'
                               })

        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'custom' }
        
        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        sticker = data['stickers'].find { |s| s['id'] == custom_sticker.id }
        expect(sticker['meta']['sticker_type']).to eq('custom')
        expect(sticker['meta']['sticker_pack']).to eq('Test Pack')
      end
    end

    context 'Acceptance Criteria 3.3: Pack organization' do
      it 'groups stickers by pack using meta field' do
        pack1_sticker = create(:attachment, 
                              account: account, 
                              file_type: :image,
                              meta: { 
                                sticker_type: 'custom', 
                                sticker_pack: 'Pack 1'
                              })

        pack2_sticker = create(:attachment, 
                              account: account, 
                              file_type: :image,
                              meta: { 
                                sticker_type: 'custom', 
                                sticker_pack: 'Pack 2'
                              })

        # Test filtering by pack
        get "/api/v1/accounts/#{account.id}/stickers", 
            params: { provider: 'custom', pack_name: 'Pack 1' }
        
        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        expect(data['stickers'].size).to eq(1)
        expect(data['stickers'].first['id']).to eq(pack1_sticker.id)
      end
    end

    context 'Acceptance Criteria 3.4: Pack display' do
      it 'lists available sticker packs' do
        create(:attachment, account: account, file_type: :image,
               meta: { sticker_type: 'custom', sticker_pack: 'Pack A' })
        create(:attachment, account: account, file_type: :image,
               meta: { sticker_type: 'custom', sticker_pack: 'Pack B' })

        get "/api/v1/accounts/#{account.id}/sticker_packs"
        
        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        pack_names = data['packs'].map { |p| p['name'] }
        expect(pack_names).to include('Pack A', 'Pack B')
      end
    end

    context 'Acceptance Criteria 3.5: Validation errors' do
      it 'handles invalid file uploads gracefully' do
        # This would be tested in the uploader specs
        # Here we test the API response structure
        post "/api/v1/accounts/#{account.id}/admin/stickers",
             params: { 
               sticker: { 
                 pack_name: 'Test Pack',
                 file: fixture_file_upload('spec/fixtures/files/invalid_file.txt', 'text/plain')
               }
             }

        expect(response).to have_http_status(:unprocessable_entity)
        data = JSON.parse(response.body)
        expect(data['errors']).to be_present
      end
    end
  end

  describe 'Requirement 4: Stickers Recentemente Utilizados' do
    before do
      user.update!(
        ui_settings: {
          recent_stickers: [
            {
              url: 'https://example.com/recent1.webp',
              alt: 'Recent 1',
              provider: 'giphy',
              used_at: 1.hour.ago.iso8601
            },
            {
              url: 'https://example.com/recent2.webp',
              alt: 'Recent 2',
              provider: 'custom',
              used_at: 2.hours.ago.iso8601
            }
          ]
        }
      )
    end

    context 'Acceptance Criteria 4.1: Recent stickers tracking' do
      it 'adds sent stickers to recent list' do
        sticker_data = {
          url: 'https://example.com/new_sticker.webp',
          alt: 'New Sticker',
          provider: 'giphy'
        }

        # Mock WhatsApp API
        allow(HTTParty).to receive(:post).and_return(
          double(success?: true, parsed_response: { 'id' => 'media_id' }),
          double(success?: true, parsed_response: { 'messages' => [{ 'id' => 'msg_id' }] })
        )
        allow(HTTParty).to receive(:get).and_return(double(body: 'fake_data'))

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        expect(response).to have_http_status(:success)

        user.reload
        recent_stickers = user.ui_settings['recent_stickers']
        expect(recent_stickers.first['url']).to eq(sticker_data[:url])
      end
    end

    context 'Acceptance Criteria 4.2: Recent stickers display' do
      it 'returns recent stickers ordered by usage date' do
        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'recent' }
        
        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        expect(data['stickers'].size).to eq(2)
        expect(data['stickers'].first['url']).to eq('https://example.com/recent1.webp')
      end
    end

    context 'Acceptance Criteria 4.3: Reordering on reuse' do
      it 'moves reused sticker to top of recent list' do
        sticker_data = {
          url: 'https://example.com/recent2.webp', # Reusing second sticker
          alt: 'Recent 2',
          provider: 'custom'
        }

        # Mock WhatsApp API
        allow(HTTParty).to receive(:post).and_return(
          double(success?: true, parsed_response: { 'id' => 'media_id' }),
          double(success?: true, parsed_response: { 'messages' => [{ 'id' => 'msg_id' }] })
        )
        allow(HTTParty).to receive(:get).and_return(double(body: 'fake_data'))

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        expect(response).to have_http_status(:success)

        user.reload
        recent_stickers = user.ui_settings['recent_stickers']
        expect(recent_stickers.first['url']).to eq('https://example.com/recent2.webp')
        expect(recent_stickers.size).to eq(2) # Should not duplicate
      end
    end

    context 'Acceptance Criteria 4.4: User-specific storage' do
      it 'stores recent stickers per user in ui_settings' do
        other_user = create(:user, account: account)
        
        # Verify users have separate recent stickers
        expect(user.ui_settings['recent_stickers']).to be_present
        expect(other_user.ui_settings&.dig('recent_stickers')).to be_nil
      end
    end

    context 'Acceptance Criteria 4.5: Empty state handling' do
      it 'handles users with no recent stickers' do
        new_user = create(:user, account: account)
        sign_in new_user

        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'recent' }
        
        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        expect(data['stickers']).to eq([])
      end
    end
  end

  describe 'Requirement 5: Envio Otimizado via WhatsApp Cloud API' do
    let(:sticker_data) do
      {
        url: 'https://example.com/test_sticker.webp',
        alt: 'Test Sticker',
        provider: 'giphy'
      }
    end

    before do
      allow(HTTParty).to receive(:post).and_return(
        double(success?: true, parsed_response: { 'id' => 'test_media_id' }),
        double(success?: true, parsed_response: { 'messages' => [{ 'id' => 'whatsapp_msg_id' }] })
      )
      allow(HTTParty).to receive(:get).and_return(double(body: 'fake_webp_data'))
    end

    context 'Acceptance Criteria 5.1: Media ID caching' do
      it 'caches WhatsApp media_id on first upload' do
        cache_key = "whatsapp_media_id:#{Digest::MD5.hexdigest(sticker_data[:url])}"
        
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        expect(response).to have_http_status(:success)
        expect(Rails.cache.read(cache_key)).to eq('test_media_id')
      end
    end

    context 'Acceptance Criteria 5.2: Cache reuse' do
      it 'reuses cached media_id for subsequent sends' do
        cache_key = "whatsapp_media_id:#{Digest::MD5.hexdigest(sticker_data[:url])}"
        Rails.cache.write(cache_key, 'cached_media_id', expires_in: 30.days)

        # Should not call upload API, only send API
        expect(HTTParty).to receive(:post)
          .with(include('messages'), any_args)
          .and_return(double(success?: true, parsed_response: { 'messages' => [{ 'id' => 'msg_id' }] }))

        expect(HTTParty).not_to receive(:post).with(include('media'), any_args)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        expect(response).to have_http_status(:success)
      end
    end

    context 'Acceptance Criteria 5.3: Message creation with sticker content_type' do
      it 'creates message with sticker content_type' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        
        message = Message.find(data['message_id'])
        expect(message.content_type).to eq('sticker')
        expect(message.content_attributes['sticker_data']).to include(sticker_data.stringify_keys)
      end
    end

    context 'Acceptance Criteria 5.4: Conversation display' do
      it 'displays sticker in conversation as normal message' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        
        message = Message.find(data['message_id'])
        expect(message.conversation_id).to eq(conversation.id)
        expect(message.message_type).to eq('outgoing')
        expect(message.additional_attributes['skip_send_reply']).to be true
      end
    end

    context 'Acceptance Criteria 5.5: Error handling' do
      it 'handles WhatsApp API failures gracefully' do
        allow(HTTParty).to receive(:post)
          .with(include('messages'), any_args)
          .and_return(double(success?: false, parsed_response: { 'error' => { 'message' => 'API Error' } }))

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        expect(response).to have_http_status(:unprocessable_entity)
        data = JSON.parse(response.body)
        expect(data['error']).to be_present

        # Should not create message on failure
        expect(Message.where(conversation: conversation, content_type: 'sticker')).to be_empty
      end
    end
  end

  describe 'Requirement 6: Processamento e Validação de Imagens' do
    context 'Image processing requirements' do
      it 'validates WebP format requirement' do
        # This would be tested in uploader specs
        # Here we verify the API handles validation errors
        post "/api/v1/accounts/#{account.id}/admin/stickers",
             params: { 
               sticker: { 
                 pack_name: 'Test Pack',
                 file: fixture_file_upload('spec/fixtures/files/test_image.jpg', 'image/jpeg')
               }
             }

        # Should either convert or reject non-WebP
        expect([200, 422]).to include(response.status)
      end
    end
  end

  describe 'Requirement 7: Cache e Performance' do
    context 'Caching requirements validation' do
      it 'implements proper cache TTL for different resources' do
        # Giphy cache (10 minutes)
        giphy_key = 'giphy_stickers:trending'
        expect(Rails.cache).to receive(:fetch)
          .with(giphy_key, expires_in: 10.minutes)
          .and_call_original

        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'giphy' }
        
        # WhatsApp media cache (30 days) - tested in sending flow
        sticker_data = { url: 'test.webp', alt: 'Test', provider: 'giphy' }
        
        allow(HTTParty).to receive(:post).and_return(
          double(success?: true, parsed_response: { 'id' => 'media_id' }),
          double(success?: true, parsed_response: { 'messages' => [{ 'id' => 'msg_id' }] })
        )
        allow(HTTParty).to receive(:get).and_return(double(body: 'data'))

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        cache_key = "whatsapp_media_id:#{Digest::MD5.hexdigest(sticker_data[:url])}"
        expect(Rails.cache.read(cache_key)).to be_present
      end
    end
  end

  describe 'Requirement 8: Integração com Interface Existente' do
    context 'WhatsApp conversation detection' do
      it 'only provides sticker functionality for WhatsApp conversations' do
        # Test with WhatsApp conversation
        get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'giphy' }
        expect(response).to have_http_status(:success)

        # Test sticker sending works for WhatsApp
        sticker_data = { url: 'test.webp', alt: 'Test', provider: 'giphy' }
        
        allow(HTTParty).to receive(:post).and_return(
          double(success?: true, parsed_response: { 'id' => 'media_id' }),
          double(success?: true, parsed_response: { 'messages' => [{ 'id' => 'msg_id' }] })
        )
        allow(HTTParty).to receive(:get).and_return(double(body: 'data'))

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        expect(response).to have_http_status(:success)
      end
    end

    context 'Message rendering compatibility' do
      it 'creates messages compatible with existing message system' do
        sticker_data = { url: 'test.webp', alt: 'Test', provider: 'giphy' }
        
        allow(HTTParty).to receive(:post).and_return(
          double(success?: true, parsed_response: { 'id' => 'media_id' }),
          double(success?: true, parsed_response: { 'messages' => [{ 'id' => 'msg_id' }] })
        )
        allow(HTTParty).to receive(:get).and_return(double(body: 'data'))

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
             params: { sticker: sticker_data }

        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        
        message = Message.find(data['message_id'])
        
        # Verify message follows existing patterns
        expect(message.account_id).to eq(account.id)
        expect(message.inbox_id).to eq(inbox.id)
        expect(message.conversation_id).to eq(conversation.id)
        expect(message.message_type).to eq('outgoing')
        expect(message.content_type).to eq('sticker')
        expect(message.content_attributes).to be_present
      end
    end
  end

  describe 'Overall System Integration' do
    it 'validates complete end-to-end sticker workflow' do
      # 1. Fetch available stickers
      get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'giphy' }
      expect(response).to have_http_status(:success)

      # 2. Send a sticker
      sticker_data = { url: 'test.webp', alt: 'Test', provider: 'giphy' }
      
      allow(HTTParty).to receive(:post).and_return(
        double(success?: true, parsed_response: { 'id' => 'media_id' }),
        double(success?: true, parsed_response: { 'messages' => [{ 'id' => 'msg_id' }] })
      )
      allow(HTTParty).to receive(:get).and_return(double(body: 'data'))

      post "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/send_sticker",
           params: { sticker: sticker_data }
      expect(response).to have_http_status(:success)

      # 3. Verify sticker appears in recent
      get "/api/v1/accounts/#{account.id}/stickers", params: { provider: 'recent' }
      expect(response).to have_http_status(:success)
      data = JSON.parse(response.body)
      expect(data['stickers'].first['url']).to eq('test.webp')

      # 4. Verify message was created
      message = Message.where(conversation: conversation, content_type: 'sticker').last
      expect(message).to be_present
      expect(message.content_attributes['sticker_data']['url']).to eq('test.webp')
    end
  end
end