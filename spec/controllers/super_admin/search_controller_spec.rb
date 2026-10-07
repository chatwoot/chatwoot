require 'rails_helper'

RSpec.describe 'Super Admin Search', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'GET /super_admin/search/accounts' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/search/accounts', params: { q: 'acme' }
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      let!(:account) { create(:account, name: 'Acme Corp') }
      let!(:other_account) { create(:account, name: 'Globex') }

      before { sign_in(super_admin, scope: :super_admin) }

      it 'lists the accounts whose name matches' do
        get '/super_admin/search/accounts', params: { q: 'acme' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Acme Corp', "/super_admin/accounts/#{account.id}")
        expect(response.body).not_to include(other_account.name)
      end

      it 'finds an account by id when the query is a number' do
        create(:account, name: "Studio #{account.id}")

        get '/super_admin/search/accounts', params: { q: account.id.to_s }

        expect(response.body).to include('Acme Corp')
        expect(response.body).not_to include("Studio #{account.id}")
      end

      it 'shows five accounts and links to the list page when there are more' do
        create_list(:account, 5, name: 'Acme Branch')

        get '/super_admin/search/accounts', params: { q: 'acme' }

        expect(response.body.scan('data-command-item').size).to eq(6)
        expect(response.body).to include('See all matching accounts', '/super_admin/accounts?search=acme')
      end

      it 'does not link to the list page when every match is shown' do
        create_list(:account, 4, name: 'Acme Branch')

        get '/super_admin/search/accounts', params: { q: 'acme' }

        expect(response.body.scan('data-command-item').size).to eq(5)
        expect(response.body).not_to include('See all matching accounts')
      end

      it 'matches wildcard characters literally' do
        create(:account, name: 'acmeXtest')
        create(:account, name: 'acme_test')

        get '/super_admin/search/accounts', params: { q: 'acme_t' }

        expect(response.body).to include('acme_test')
        expect(response.body).not_to include('acmeXtest')
      end

      it 'renders nothing for an id beyond the column range' do
        get '/super_admin/search/accounts', params: { q: '99999999999999999999999' }

        expect(response).to have_http_status(:success)
        expect(response.body).to be_blank
      end

      it 'renders nothing when no account matches' do
        get '/super_admin/search/accounts', params: { q: 'nothing' }

        expect(response.body).to be_blank
      end
    end
  end

  describe 'GET /super_admin/search/users' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/search/users', params: { q: 'jane' }
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      let!(:user) { create(:user, name: 'Jane Doe', email: 'jane@acme.com') }
      let!(:other_user) { create(:user, name: 'John Roe', email: 'john@globex.com') }

      before { sign_in(super_admin, scope: :super_admin) }

      it 'lists the users whose name or email matches' do
        get '/super_admin/search/users', params: { q: 'acme' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Jane Doe', 'jane@acme.com', "/super_admin/users/#{user.id}")
        expect(response.body).not_to include('John Roe')
      end

      it 'finds a user by id when the query is a number' do
        get '/super_admin/search/users', params: { q: other_user.id.to_s }

        expect(response.body).to include('John Roe')
        expect(response.body).not_to include('Jane Doe')
      end

      it 'links super admins to the users page' do
        get '/super_admin/search/users', params: { q: super_admin.email }

        expect(response.body).to include("/super_admin/users/#{super_admin.id}")
      end
    end
  end
end
