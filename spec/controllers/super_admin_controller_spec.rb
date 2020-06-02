require 'rails_helper'

RSpec.describe 'Super Admin', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'request to /super_admin' do
    context 'when the super admin is unauthenticated' do
      it 'redirects to signin page' do
        get '/super_admin/'
        expect(response).to have_http_status(:redirect)
        expect(response.body).to include('sign_in')
      end

      it 'signs super admin in and out' do
        sign_in super_admin
        get '/super_admin'
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Dashboard')

        sign_out super_admin
        get '/super_admin'
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'request to /super_admin/sidekiq' do
    context 'when the super admin is unauthenticated' do
      it 'redirects to signin page' do
        get '/monitoring/sidekiq'
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include('sign_in')
      end

      it 'signs super admin in and out' do
        sign_in super_admin
        get '/monitoring/sidekiq'
        expect(response).to have_http_status(:success)

        sign_out super_admin
        get '/monitoring/sidekiq'
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
