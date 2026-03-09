require 'rails_helper'

RSpec.describe 'Stickers API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:administrator) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/{account.id}/stickers' do
    context 'when provider is giphy' do
      let(:giphy_stickers) do
        [
          { id: 'giphy_1', url: 'https://giphy.com/1.webp', alt: 'Funny', provider: 'giphy' },
          { id: 'giphy_2', url: 'https://giphy.com/2.webp', alt: 'Happy', provider: 'giphy' }
        ]
      end

      before do
        allow_any_instance_of(GiphyService).to receive(:search_or_trending).and_return(giphy_stickers)
      end

      it 'returns giphy stickers for search' do
        get "/api/v1/accounts/#{account.id}/stickers", 
            params: { provider: 'giphy', search_term: 'funny' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['stickers']).to eq(giphy_stickers.as_json)
      end

      it 'returns trending giphy stickers when no search term' do
        get "/api/v1/accounts/#{account.id}/stickers", 
            params: { provider: 'giphy' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['stickers']).to eq(giphy_stickers.as_json)
      end

      context 'when Giphy service returns error' do
        let(:giphy_error_response) do
          {
            error: 'GIPHY_API_KEY_MISSING',
            message: 'Giphy integration not configured',
            stickers: []
          }
        end

        before do
          allow_any_instance_of(GiphyService).to receive(:search_or_trending).and_return(giphy_error_response)
        end

        it 'returns error response with 422 status' do
          get "/api/v1/accounts/#{account.id}/stickers", 
              params: { provider: 'giphy' },
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('GIPHY_API_KEY_MISSING')
          expect(json_response['message']).to eq('Giphy integration not configured')
          expect(json_response['stickers']).to eq([])
        end
      end

      context 'when Giphy service raises exception' do
        before do
          allow_any_instance_of(GiphyService).to receive(:search_or_trending).and_raise(GiphyService::ApiUnavailableError.new('Service down'))
        end

        it 'handles exception and returns service unavailable' do
          get "/api/v1/accounts/#{account.id}/stickers", 
              params: { provider: 'giphy' },
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:service_unavailable)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('GIPHY_UNAVAILABLE')
          expect(json_response['user_message']).to eq('Giphy service temporarily unavailable.')
        end
      end
    end

    context 'when provider is custom' do
      let(:custom_stickers) do
        [
          { id: 1, url: 'https://example.com/custom1.webp', alt: 'Company', provider: 'custom' },
          { id: 2, url: 'https://example.com/custom2.webp', alt: 'Company', provider: 'custom' }
        ]
      end

      before do
        allow_any_instance_of(StickerService).to receive(:custom_stickers).and_return(custom_stickers)
      end

      it 'returns custom stickers' do
        get "/api/v1/accounts/#{account.id}/stickers", 
            params: { provider: 'custom' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['stickers']).to eq(custom_stickers.as_json)
      end

      it 'passes pack_name parameter to service' do
        expect_any_instance_of(StickerService).to receive(:custom_stickers).with('Company')

        get "/api/v1/accounts/#{account.id}/stickers", 
            params: { provider: 'custom', pack_name: 'Company' },
            headers: agent.create_new_auth_token,
            as: :json
      end
    end

    context 'when provider is recent' do
      let(:recent_stickers_data) do
        [
          {
            'url' => 'https://giphy.com/recent1.webp',
            'alt' => 'Recent Sticker',
            'provider' => 'giphy',
            'used_at' => '2024-01-01T10:00:00Z'
          }
        ]
      end

      before do
        agent.update!(ui_settings: { 'recent_stickers' => recent_stickers_data })
      end

      it 'returns recent stickers for the current user' do
        get "/api/v1/accounts/#{account.id}/stickers", 
            params: { provider: 'recent' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['stickers'].length).to eq(1)
        expect(json_response['stickers'].first['url']).to eq('https://giphy.com/recent1.webp')
        expect(json_response['stickers'].first['provider']).to eq('giphy')
      end

      it 'returns empty array when user has no recent stickers' do
        agent.update!(ui_settings: {})

        get "/api/v1/accounts/#{account.id}/stickers", 
            params: { provider: 'recent' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['stickers']).to eq([])
      end
    end

    context 'when provider is unknown' do
      it 'returns error for invalid provider' do
        get "/api/v1/accounts/#{account.id}/stickers", 
            params: { provider: 'unknown' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('INVALID_PROVIDER')
        expect(json_response['message']).to eq('Invalid provider specified')
        expect(json_response['stickers']).to eq([])
      end
    end

    context 'when no provider is specified' do
      it 'returns error for missing provider' do
        get "/api/v1/accounts/#{account.id}/stickers",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('INVALID_PROVIDER')
      end
    end

    context 'when unexpected error occurs' do
      before do
        allow_any_instance_of(GiphyService).to receive(:search_or_trending).and_raise(StandardError.new('Unexpected error'))
      end

      it 'returns internal server error' do
        get "/api/v1/accounts/#{account.id}/stickers", 
            params: { provider: 'giphy' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('UNKNOWN_ERROR')
        expect(json_response['message']).to eq('An unexpected error occurred. Please try again.')
        expect(json_response['stickers']).to eq([])
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/stickers/packs' do
    let(:sticker_packs) do
      [
        { id: 'Company', name: 'Company' },
        { id: 'Fun', name: 'Fun' }
      ]
    end

    before do
      allow_any_instance_of(StickerService).to receive(:custom_sticker_packs).and_return(sticker_packs)
    end

    it 'returns custom sticker packs' do
      get "/api/v1/accounts/#{account.id}/stickers/packs",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['packs']).to eq(sticker_packs.as_json)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/stickers/send_sticker' do
    let(:whatsapp_channel) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false) }
    let(:whatsapp_inbox) { whatsapp_channel.inbox }
    let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox) }
    let(:sticker_params) { { url: 'https://giphy.com/test.webp', alt: 'Test', provider: 'giphy', id: 'test123' } }

    context 'when conversation is WhatsApp' do
      context 'when sticker sending succeeds' do
        let(:service_result) { { success: true, message_id: 123 } }

        before do
          allow(Whatsapp::SendStickerService).to receive(:new).and_return(
            instance_double(Whatsapp::SendStickerService, perform: service_result)
          )
        end

        it 'calls SendStickerService and returns success' do
          expect(Whatsapp::SendStickerService).to receive(:new).with(
            conversation: conversation,
            sticker_data: sticker_params.symbolize_keys,
            user: agent
          )

          post "/api/v1/accounts/#{account.id}/stickers/send_sticker",
               params: {
                 conversation_id: conversation.id,
                 sticker: sticker_params
               },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be true
          expect(json_response['message_id']).to eq(123)
        end
      end

      context 'when sticker sending fails' do
        let(:service_result) do
          {
            success: false,
            error: 'Failed to upload media',
            error_code: 'MEDIA_UPLOAD_FAILED',
            user_message: 'Failed to upload sticker. Please try again.'
          }
        end

        before do
          allow(Whatsapp::SendStickerService).to receive(:new).and_return(
            instance_double(Whatsapp::SendStickerService, perform: service_result)
          )
        end

        it 'returns error from service with user-friendly message' do
          post "/api/v1/accounts/#{account.id}/stickers/send_sticker",
               params: {
                 conversation_id: conversation.id,
                 sticker: sticker_params
               },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be false
          expect(json_response['error']).to eq('Failed to upload media')
          expect(json_response['error_code']).to eq('MEDIA_UPLOAD_FAILED')
          expect(json_response['user_message']).to eq('Failed to upload sticker. Please try again.')
        end
      end

      context 'when validation fails' do
        it 'returns error for missing conversation_id' do
          post "/api/v1/accounts/#{account.id}/stickers/send_sticker",
               params: {
                 sticker: sticker_params
               },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:internal_server_error)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('UNKNOWN_ERROR')
          expect(json_response['user_message']).to eq('Unable to send sticker. Please try again.')
        end

        it 'returns error for missing sticker data' do
          post "/api/v1/accounts/#{account.id}/stickers/send_sticker",
               params: {
                 conversation_id: conversation.id
               },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:internal_server_error)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('UNKNOWN_ERROR')
        end

        it 'returns error for missing sticker URL' do
          invalid_sticker = sticker_params.except(:url)
          
          post "/api/v1/accounts/#{account.id}/stickers/send_sticker",
               params: {
                 conversation_id: conversation.id,
                 sticker: invalid_sticker
               },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:internal_server_error)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('UNKNOWN_ERROR')
        end
      end

      context 'when SendStickerService raises exception' do
        before do
          allow(Whatsapp::SendStickerService).to receive(:new).and_raise(
            Whatsapp::SendStickerService::InvalidStickerDataError.new('Invalid sticker')
          )
        end

        it 'handles exception and returns appropriate error' do
          post "/api/v1/accounts/#{account.id}/stickers/send_sticker",
               params: {
                 conversation_id: conversation.id,
                 sticker: sticker_params
               },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('INVALID_STICKER')
          expect(json_response['user_message']).to eq('Invalid sticker data.')
        end
      end
    end

    context 'when conversation is not WhatsApp' do
      let(:email_channel) { create(:channel_email, account: account) }
      let(:email_inbox) { email_channel.inbox }
      let(:email_conversation) { create(:conversation, account: account, inbox: email_inbox) }

      it 'returns unprocessable entity error with user-friendly message' do
        post "/api/v1/accounts/#{account.id}/stickers/send_sticker",
             params: {
               conversation_id: email_conversation.id,
               sticker: sticker_params
             },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('INVALID_CHANNEL_TYPE')
        expect(json_response['message']).to eq('Stickers are only supported for WhatsApp conversations')
        expect(json_response['user_message']).to eq('Stickers can only be sent in WhatsApp conversations.')
      end
    end

    context 'when conversation does not exist' do
      it 'returns not found error with user-friendly message' do
        post "/api/v1/accounts/#{account.id}/stickers/send_sticker",
             params: {
               conversation_id: 999_999,
               sticker: sticker_params
             },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('CONVERSATION_NOT_FOUND')
        expect(json_response['message']).to eq('Conversation not found')
        expect(json_response['user_message']).to eq('Conversation not found. Please refresh the page and try again.')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/stickers/upload' do
    let(:test_file) { fixture_file_upload('spec/fixtures/files/test_image.png', 'image/png') }
    let(:pack_name) { 'Test Pack' }
    let(:tags) { ['test', 'sample'] }

    context 'when upload succeeds' do
      let(:service_result) do
        {
          success: true,
          sticker: {
            id: 123,
            url: 'https://example.com/sticker.webp',
            alt: pack_name,
            provider: 'custom',
            meta: { 'sticker_type' => 'custom' }
          }
        }
      end

      before do
        allow_any_instance_of(StickerService).to receive(:create_custom_sticker).and_return(service_result)
      end

      it 'creates a custom sticker successfully' do
        expect_any_instance_of(StickerService).to receive(:create_custom_sticker).with(
          pack_name,
          test_file,
          tags
        )

        post "/api/v1/accounts/#{account.id}/stickers/upload",
             params: {
               file: test_file,
               pack_name: pack_name,
               tags: tags
             },
             headers: administrator.create_new_auth_token

        if response.status == 500
          puts "Response body: #{response.body}"
        end
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['sticker']['id']).to eq(123)
        expect(json_response['sticker']['provider']).to eq('custom')
      end
    end

    context 'when upload fails' do
      let(:service_result) do
        {
          success: false,
          errors: ['File is too large', 'Invalid format'],
          error_code: 'VALIDATION_ERROR',
          user_message: 'Please check your sticker file and try again.'
        }
      end

      before do
        allow_any_instance_of(StickerService).to receive(:create_custom_sticker).and_return(service_result)
      end

      it 'returns error messages with user-friendly message' do
        post "/api/v1/accounts/#{account.id}/stickers/upload",
             params: {
               file: test_file,
               pack_name: pack_name
             },
             headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['errors']).to eq(['File is too large', 'Invalid format'])
        expect(json_response['error_code']).to eq('VALIDATION_ERROR')
        expect(json_response['user_message']).to eq('Please check your sticker file and try again.')
      end
    end

    context 'when validation fails' do
      it 'returns error for missing file' do
        post "/api/v1/accounts/#{account.id}/stickers/upload",
             params: {
               pack_name: pack_name
             },
             headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('UPLOAD_ERROR')
        expect(json_response['user_message']).to eq('Failed to upload sticker. Please try again.')
      end

      it 'returns error for missing pack_name' do
        post "/api/v1/accounts/#{account.id}/stickers/upload",
             params: {
               file: test_file
             },
             headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('UPLOAD_ERROR')
      end

      it 'returns error for file too large' do
        large_file = double('large_file', size: 6.megabytes, respond_to?: true)
        
        post "/api/v1/accounts/#{account.id}/stickers/upload",
             params: {
               file: large_file,
               pack_name: pack_name
             },
             headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('UPLOAD_ERROR')
      end
    end

    context 'when StickerService raises exception' do
      before do
        allow_any_instance_of(StickerService).to receive(:create_custom_sticker).and_raise(
          StickerService::ValidationError.new('Invalid pack name')
        )
      end

      it 'handles exception and returns appropriate error' do
        post "/api/v1/accounts/#{account.id}/stickers/upload",
             params: {
               file: test_file,
               pack_name: pack_name
             },
             headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('VALIDATION_ERROR')
        expect(json_response['user_message']).to eq('Invalid input. Please check your data and try again.')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/stickers/:id' do
    let(:sticker_id) { 123 }

    context 'when deletion succeeds' do
      let(:service_result) { { success: true } }

      before do
        allow_any_instance_of(StickerService).to receive(:delete_custom_sticker).and_return(service_result)
      end

      it 'deletes the sticker successfully' do
        expect_any_instance_of(StickerService).to receive(:delete_custom_sticker).with(sticker_id.to_s)

        delete "/api/v1/accounts/#{account.id}/stickers/#{sticker_id}",
               headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
      end
    end

    context 'when deletion fails' do
      let(:service_result) { { success: false, error: 'Sticker not found' } }

      before do
        allow_any_instance_of(StickerService).to receive(:delete_custom_sticker).and_return(service_result)
      end

      it 'returns error message' do
        delete "/api/v1/accounts/#{account.id}/stickers/#{sticker_id}",
               headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Sticker not found')
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/stickers/:id/pack' do
    let(:sticker_id) { 123 }
    let(:new_pack_name) { 'New Pack' }

    context 'when update succeeds' do
      let(:service_result) { { success: true } }

      before do
        allow_any_instance_of(StickerService).to receive(:update_sticker_pack).and_return(service_result)
      end

      it 'updates the sticker pack successfully' do
        expect_any_instance_of(StickerService).to receive(:update_sticker_pack).with(
          sticker_id.to_s,
          new_pack_name
        )

        patch "/api/v1/accounts/#{account.id}/stickers/#{sticker_id}/pack",
              params: { pack_name: new_pack_name },
              headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
      end
    end

    context 'when update fails' do
      let(:service_result) { { success: false, error: 'Sticker not found' } }

      before do
        allow_any_instance_of(StickerService).to receive(:update_sticker_pack).and_return(service_result)
      end

      it 'returns error message' do
        patch "/api/v1/accounts/#{account.id}/stickers/#{sticker_id}/pack",
              params: { pack_name: new_pack_name },
              headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Sticker not found')
      end
    end
  end

  describe 'authorization' do
    context 'when user is not authenticated' do
      it 'returns unauthorized for index' do
        get "/api/v1/accounts/#{account.id}/stickers", 
            params: { provider: 'giphy' }

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns unauthorized for packs' do
        get "/api/v1/accounts/#{account.id}/stickers/packs"

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns unauthorized for send_sticker' do
        post "/api/v1/accounts/#{account.id}/stickers/send_sticker",
             params: {
               conversation_id: 1,
               sticker: { url: 'test', alt: 'test', provider: 'giphy' }
             }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user belongs to different account' do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, account: other_account, role: :agent) }

      it 'returns unauthorized for index' do
        get "/api/v1/accounts/#{account.id}/stickers", 
            params: { provider: 'giphy' },
            headers: other_user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end