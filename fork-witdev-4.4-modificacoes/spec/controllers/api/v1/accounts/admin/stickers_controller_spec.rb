require 'rails_helper'

RSpec.describe Api::V1::Accounts::Admin::StickersController, type: :controller do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:sticker) { create(:attachment, account: account, file_type: :image, meta: { sticker_type: 'custom', sticker_pack: 'Test Pack' }) }

  describe 'GET #index' do
    before do
      create_list(:attachment, 3, account: account, file_type: :image, meta: { sticker_type: 'custom', sticker_pack: 'Pack 1' })
      create_list(:attachment, 2, account: account, file_type: :image, meta: { sticker_type: 'custom', sticker_pack: 'Pack 2' })
    end

    context 'when it is an authenticated administrator' do
      it 'returns all custom stickers' do
        sign_in(administrator)
        get :index, params: { account_id: account.id }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['stickers']).to be_an(Array)
        expect(json_response['stickers'].length).to eq(5)
        expect(json_response['pagination']['total_count']).to eq(5)
      end

      it 'filters stickers by pack name' do
        sign_in(administrator)
        get :index, params: { account_id: account.id, pack_name: 'Pack 1' }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['stickers'].length).to eq(3)
        json_response['stickers'].each do |sticker|
          expect(sticker['pack_name']).to eq('Pack 1')
        end
      end

      it 'supports pagination' do
        sign_in(administrator)
        get :index, params: { account_id: account.id, page: 1, per_page: 2 }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['stickers'].length).to eq(2)
        expect(json_response['pagination']['current_page']).to eq(1)
        expect(json_response['pagination']['per_page']).to eq(2)
        expect(json_response['pagination']['total_pages']).to eq(3)
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
      it 'returns sticker details' do
        sign_in(administrator)
        get :show, params: { account_id: account.id, id: sticker.id }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['id']).to eq(sticker.id)
        expect(json_response['pack_name']).to eq('Test Pack')
      end

      it 'returns not found for non-existent sticker' do
        sign_in(administrator)
        get :show, params: { account_id: account.id, id: 999999 }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    let(:test_file) { fixture_file_upload('spec/fixtures/files/test_image.png', 'image/png') }

    context 'when it is an authenticated administrator' do
      it 'creates a new sticker' do
        sign_in(administrator)
        
        allow(StickerService).to receive(:new).and_return(double(
          create_custom_sticker: { 
            id: 1, 
            url: 'test.webp', 
            alt: 'Test Pack',
            provider: 'custom',
            meta: { sticker_pack: 'Test Pack', tags: ['test'] }
          }
        ))

        post :create, params: { 
          account_id: account.id,
          pack_name: 'Test Pack',
          file: test_file,
          tags: ['test', 'sample']
        }

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        expect(json_response['provider']).to eq('custom')
      end

      it 'returns error for missing pack name' do
        sign_in(administrator)
        post :create, params: { 
          account_id: account.id,
          file: test_file
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to eq('Pack name is required')
      end

      it 'returns error for missing file' do
        sign_in(administrator)
        post :create, params: { 
          account_id: account.id,
          pack_name: 'Test Pack'
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to eq('File is required')
      end

      it 'handles StickerService errors' do
        sign_in(administrator)
        
        allow(StickerService).to receive(:new).and_return(double(
          create_custom_sticker: -> { raise StandardError, 'Invalid file format' }
        ))

        post :create, params: { 
          account_id: account.id,
          pack_name: 'Test Pack',
          file: test_file
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to eq('Invalid file format')
      end
    end
  end

  describe 'PUT #update' do
    context 'when it is an authenticated administrator' do
      it 'updates sticker metadata' do
        sign_in(administrator)
        put :update, params: { 
          account_id: account.id,
          id: sticker.id,
          pack_name: 'Updated Pack',
          tags: ['updated', 'tag']
        }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['pack_name']).to eq('Updated Pack')
        expect(json_response['tags']).to eq(['updated', 'tag'])

        # Verify database was updated
        sticker.reload
        expect(sticker.meta['sticker_pack']).to eq('Updated Pack')
        expect(sticker.meta['tags']).to eq(['updated', 'tag'])
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when it is an authenticated administrator' do
      it 'deletes the sticker' do
        sign_in(administrator)
        delete :destroy, params: { account_id: account.id, id: sticker.id }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['message']).to eq('Sticker deleted successfully')

        expect { sticker.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'POST #validate_file' do
    let(:test_file) { fixture_file_upload('spec/fixtures/files/test_image.png', 'image/png') }

    context 'when it is an authenticated administrator' do
      it 'validates a valid file' do
        sign_in(administrator)
        
        # Mock StickerUploader
        uploader_double = double('StickerUploader')
        allow(StickerUploader).to receive(:new).and_return(uploader_double)
        allow(uploader_double).to receive(:store!)
        allow(uploader_double).to receive(:url).and_return('http://example.com/test.webp')

        post :validate_file, params: { 
          account_id: account.id,
          file: test_file
        }

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['valid']).to be true
        expect(json_response['filename']).to eq('test_image.png')
        expect(json_response['preview_url']).to eq('http://example.com/test.webp')
      end

      it 'returns validation error for invalid file' do
        sign_in(administrator)
        
        # Mock StickerUploader to raise error
        uploader_double = double('StickerUploader')
        allow(StickerUploader).to receive(:new).and_return(uploader_double)
        allow(uploader_double).to receive(:store!).and_raise(StandardError, 'Invalid file format')

        post :validate_file, params: { 
          account_id: account.id,
          file: test_file
        }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['valid']).to be false
        expect(json_response['error']).to eq('Invalid file format')
      end

      it 'returns error for missing file' do
        sign_in(administrator)
        post :validate_file, params: { account_id: account.id }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response['error']).to eq('No file provided')
      end
    end
  end
end