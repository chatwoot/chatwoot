require 'rails_helper'

RSpec.describe Facebook::ConfirmController do
  describe 'GET #show' do
    let(:user_id) { '12345' }

    context 'when deletion is in progress' do
      before do
        redis_key = format(Redis::Alfred::META_DELETE_PROCESSING, id: user_id)
        allow(Redis::Alfred).to receive(:get).with(redis_key).and_return('true')
      end

      it 'returns processing status' do
        get :show, params: { id: user_id }

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('Processing')
      end
    end

    context 'when deletion is completed' do
      before do
        redis_key = format(Redis::Alfred::META_DELETE_PROCESSING, id: user_id)
        allow(Redis::Alfred).to receive(:get).with(redis_key).and_return(nil)
      end

      it 'returns success message' do
        get :show, params: { id: user_id }

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('Data Deleted Successfully')
      end
    end
  end
end
