require 'rails_helper'

RSpec.describe Api::V1::Accounts::StickerPacksController, type: :controller do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  before do
    # Create some test sticker packs
    create(:attachment, 
           account: account, 
           file_type: :image,
           meta: { sticker_type: 'custom', sticker_pack: 'Company Logos' })
    create(:attachment, 
           account: account, 
           file_type: :image,
           meta: { sticker_type: 'custom', sticker_pack: 'Company Logos' })
    create(:attachment, 
           account: account, 
           file_type: :image,
           meta: { sticker_type: 'custom', sticker_pack: 'Emojis' })
  end

  describe 'GET #index' do
    context 'when it is an authenticated administrator' do
      it 'returns all sticker packs with counts' do
        sign_in(administrator)
        get :index, params: { account_id: account.id }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['sticker_packs']).to be_an(Array)
        expect(json_response['sticker_packs'].length).to eq(2)
        
        company_pack = json_response['sticker_packs'].find { |p| p['name'] == 'Company Logos' }
        expect(company_pack['sticker_count']).to eq(2)
        
        emoji_pack = json_response['sticker_packs'].find { |p| p['name'] == 'Emojis' }
        expect(emoji_pack['sticker_count']).to eq(1)
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns unauthorized' do
        sign_in(agent)
        get :index, params: { account_id: account.id }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #show' do
    context 'when it is an authenticated administrator' do
      it 'returns stickers in the specified pack' do
        sign_in(administrator)
        get :show, params: { account_id: account.id, id: 'Company Logos' }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['pack_name']).to eq('Company Logos')
        expect(json_response['stickers']).to be_an(Array)
        expect(json_response['stickers'].length).to eq(2)
        expect(json_response['total_count']).to eq(2)
      end
    end
  end

  describe 'POST #create' do
    context 'when it is an authenticated administrator' do
      it 'creates a new sticker pack' do
        sign_in(administrator)
        post :create, params: { 
          account_id: account.id, 
          sticker_pack: { name: 'New Pack' } 
        }

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        expect(json_response['pack_name']).to eq('New Pack')
        expect(json_response['message']).to eq('Sticker pack created successfully')
      end

      it 'returns error for duplicate pack name' do
        sign_in(administrator)
        post :create, params: { 
          account_id: account.id, 
          sticker_pack: { name: 'Company Logos' } 
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to eq('Sticker pack already exists')
      end

      it 'returns error for blank pack name' do
        sign_in(administrator)
        post :create, params: { 
          account_id: account.id, 
          sticker_pack: { name: '' } 
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to eq('Pack name is required')
      end
    end
  end

  describe 'PUT #update' do
    context 'when it is an authenticated administrator' do
      it 'updates sticker pack name' do
        sign_in(administrator)
        put :update, params: { 
          account_id: account.id, 
          id: 'Company Logos',
          sticker_pack: { name: 'Updated Logos' } 
        }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['old_name']).to eq('Company Logos')
        expect(json_response['new_name']).to eq('Updated Logos')

        # Verify stickers were updated
        updated_stickers = account.attachments
                                 .where("meta->>'sticker_type' = ? AND meta->>'sticker_pack' = ?", 
                                        'custom', 'Updated Logos')
        expect(updated_stickers.count).to eq(2)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when it is an authenticated administrator' do
      it 'deletes all stickers in the pack' do
        sign_in(administrator)
        delete :destroy, params: { account_id: account.id, id: 'Company Logos' }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['deleted_stickers']).to eq(2)

        # Verify stickers were deleted
        remaining_stickers = account.attachments
                                   .where("meta->>'sticker_type' = ? AND meta->>'sticker_pack' = ?", 
                                          'custom', 'Company Logos')
        expect(remaining_stickers.count).to eq(0)
      end
    end
  end

  describe 'POST #bulk_upload' do
    context 'when it is an authenticated administrator' do
      let(:test_file1) { fixture_file_upload('spec/fixtures/files/test_image.png', 'image/png') }
      let(:test_file2) { fixture_file_upload('spec/fixtures/files/test_image.png', 'image/png') }

      it 'uploads multiple stickers to a pack' do
        sign_in(administrator)
        
        allow(StickerService).to receive(:new).and_return(double(
          create_custom_sticker: { id: 1, url: 'test.webp', provider: 'custom' }
        ))

        post :bulk_upload, params: { 
          account_id: account.id,
          pack_name: 'Bulk Pack',
          files: [test_file1, test_file2]
        }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['successful']).to eq(2)
        expect(json_response['failed']).to eq(0)
      end

      it 'returns error for missing pack name' do
        sign_in(administrator)
        post :bulk_upload, params: { 
          account_id: account.id,
          files: [test_file1]
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to eq('Pack name is required')
      end

      it 'returns error for no files' do
        sign_in(administrator)
        post :bulk_upload, params: { 
          account_id: account.id,
          pack_name: 'Test Pack'
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to eq('No files provided')
      end
    end
  end
end