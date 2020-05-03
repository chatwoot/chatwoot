require 'rails_helper'

RSpec.describe 'Super Admin', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'request to /super admin' do
    context 'when the user is unauthenticated' do
      it 'redirects to signin page' do
        get '/super_admin/'
        expect(response).to have_http_status(:redirect)
        expect(response.body).to include('sign_in')
      end

      it 'signs user in and out' do
        sign_in super_admin
        get '/super_admin'
        expect(response).to have_http_status(:success)
        expect(response.body).to include('New user')

        sign_out super_admin
        get '/super_admin'
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
