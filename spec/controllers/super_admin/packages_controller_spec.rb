require 'rails_helper'

RSpec.describe 'Super Admin Packages API', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'GET /super_admin/packages' do
    context 'when it is an unauthenticated super admin' do
      it 'redirects to sign in' do
        get '/super_admin/packages'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      before { sign_in(super_admin, scope: :super_admin) }

      it 'lists packages' do
        create(:package, name: 'Starter')

        get '/super_admin/packages'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Starter')
      end
    end
  end

  describe 'POST /super_admin/packages' do
    before { sign_in(super_admin, scope: :super_admin) }

    it 'creates a package with the submitted limits' do
      post '/super_admin/packages', params: {
        package: {
          name: 'Pro',
          description: 'For growing teams',
          status: 'active',
          users_limit: 10,
          channels_limit: 2,
          contacts_limit: 500,
          conversations_limit: 100,
          campaign_messages_limit: 300
        }
      }

      expect(response).to redirect_to(super_admin_package_path(Package.last))
      expect(Package.last).to have_attributes(
        name: 'Pro',
        users_limit: 10,
        channels_limit: 2,
        contacts_limit: 500,
        conversations_limit: 100,
        campaign_messages_limit: 300
      )
    end

    it 'stores blank limits as nil (unlimited)' do
      post '/super_admin/packages', params: { package: { name: 'Free', status: 'active', users_limit: '' } }

      expect(Package.last.users_limit).to be_nil
    end

    it 'rejects a package without a name' do
      expect do
        post '/super_admin/packages', params: { package: { status: 'active' } }
      end.not_to change(Package, :count)
    end
  end

  describe 'PATCH /super_admin/packages/:id' do
    before { sign_in(super_admin, scope: :super_admin) }

    it 'updates the package' do
      package = create(:package, name: 'Starter', users_limit: 5)

      patch "/super_admin/packages/#{package.id}", params: { package: { name: 'Starter Plus', users_limit: 20 } }

      expect(package.reload).to have_attributes(name: 'Starter Plus', users_limit: 20)
    end
  end

  describe 'DELETE /super_admin/packages/:id' do
    before { sign_in(super_admin, scope: :super_admin) }

    it 'deletes the package' do
      package = create(:package)

      expect { delete "/super_admin/packages/#{package.id}" }.to change(Package, :count).by(-1)
    end
  end
end
