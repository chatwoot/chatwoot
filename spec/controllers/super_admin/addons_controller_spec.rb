require 'rails_helper'

RSpec.describe 'Super Admin Add-ons API', type: :request do
  let(:super_admin) { create(:super_admin) }
  let(:account) { create(:account) }
  let(:package) { create(:package) }

  describe 'GET /super_admin/addons' do
    context 'when it is an unauthenticated super admin' do
      it 'redirects to sign in' do
        get '/super_admin/addons'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      before { sign_in(super_admin, scope: :super_admin) }

      it 'lists add-ons' do
        create(:addon, name: 'Extra Seats', account: account, package: package)

        get '/super_admin/addons'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Extra Seats')
      end
    end
  end

  describe 'POST /super_admin/addons' do
    before { sign_in(super_admin, scope: :super_admin) }

    it 'creates an add-on with the submitted boosts' do
      post '/super_admin/addons', params: {
        addon: {
          name: 'Extra Seats',
          description: '100 more agents',
          status: 'active',
          account_id: account.id,
          package_id: package.id,
          users_limit: 100,
          channels_limit: 20,
          contacts_limit: 1000,
          conversations_limit: 500,
          campaign_messages_limit: 200,
          starts_at: 1.month.ago,
          ends_at: 1.month.from_now
        }
      }

      expect(response).to redirect_to(super_admin_addon_path(Addon.last))
      expect(Addon.last).to have_attributes(
        name: 'Extra Seats',
        account: account,
        package: package,
        users_limit: 100,
        channels_limit: 20,
        contacts_limit: 1000,
        conversations_limit: 500,
        campaign_messages_limit: 200
      )
    end

    it 'stores blank boosts as nil (no boost)' do
      post '/super_admin/addons', params: {
        addon: {
          name: 'Free Add-on',
          status: 'active',
          account_id: account.id,
          package_id: package.id,
          users_limit: '',
          starts_at: 1.month.ago,
          ends_at: 1.month.from_now
        }
      }

      expect(Addon.last.users_limit).to be_nil
    end

    it 'rejects an add-on without a name' do
      expect do
        post '/super_admin/addons', params: {
          addon: {
            status: 'active',
            account_id: account.id,
            package_id: package.id,
            starts_at: 1.month.ago,
            ends_at: 1.month.from_now
          }
        }
      end.not_to change(Addon, :count)
    end
  end

  describe 'PATCH /super_admin/addons/:id' do
    before { sign_in(super_admin, scope: :super_admin) }

    it 'updates the add-on' do
      addon = create(:addon, name: 'Extra Seats', users_limit: 100, account: account, package: package)

      patch "/super_admin/addons/#{addon.id}", params: { addon: { name: 'Extra Seats Plus', users_limit: 200 } }

      expect(addon.reload).to have_attributes(name: 'Extra Seats Plus', users_limit: 200)
    end
  end

  describe 'DELETE /super_admin/addons/:id' do
    before { sign_in(super_admin, scope: :super_admin) }

    it 'deletes the add-on' do
      addon = create(:addon, account: account, package: package)

      expect { delete "/super_admin/addons/#{addon.id}" }.to change(Addon, :count).by(-1)
    end
  end
end
