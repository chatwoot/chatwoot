require 'rails_helper'

RSpec.describe 'Super Admin Account Add-ons API', type: :request do
  let(:super_admin) { create(:super_admin) }
  # A wide package window so fixed-month and custom add-on periods fit inside it.
  let(:package) { create(:package) }
  let(:account) do
    account = create(:account, :without_package)
    create(:account_package, account: account, package: package, starts_at: 1.month.ago, ends_at: 1.year.from_now)
    account
  end
  # let! so the add-on exists before the request (the picker lists catalog rows;
  # a lazy let referenced after the GET would render an empty picker).
  let!(:addon) { create(:addon, name: 'Extra Seats', users_limit: 100) }

  describe 'GET /super_admin/account_addons/new' do
    context 'when it is an unauthenticated super admin' do
      it 'redirects to sign in' do
        get "/super_admin/account_addons/new?account_id=#{account.id}"

        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      before { sign_in(super_admin, scope: :super_admin) }

      it 'shows the available active add-ons and the account' do
        get "/super_admin/account_addons/new?account_id=#{account.id}"

        expect(response).to have_http_status(:success)
        expect(response.body).to include(addon.name)
        expect(response.body).to include(account.name)
      end

      it 'excludes inactive add-ons from the picker' do
        inactive = create(:addon, name: 'Retired Add-on', status: :inactive)

        get "/super_admin/account_addons/new?account_id=#{account.id}"

        expect(response.body).not_to include(inactive.name)
      end

      it 'shows a prompt to assign a package first when the account has none' do
        account_without_package = create(:account, :without_package)

        get "/super_admin/account_addons/new?account_id=#{account_without_package.id}"

        expect(response.body).to include('Assign a package first')
      end
    end
  end

  describe 'POST /super_admin/account_addons' do
    before { sign_in(super_admin, scope: :super_admin) }

    it 'creates an add-on with a fixed months duration' do
      start_date = Date.current

      expect do
        post '/super_admin/account_addons', params: {
          account_addon: {
            account_id: account.id,
            addon_id: addon.id,
            start_date: start_date,
            duration_type: 'fixed_months',
            duration_months: 3
          }
        }
      end.to change(AccountAddon, :count).by(1)

      account_addon = AccountAddon.last
      expect(account_addon.starts_at).to eq(start_date.beginning_of_day)
      expect(account_addon.ends_at.change(usec: 0)).to eq(start_date.advance(months: 3).end_of_day.change(usec: 0))
      expect(account_addon.duration_type).to eq('fixed_months')
      expect(account_addon.duration_months).to eq(3)
      expect(response).to redirect_to(super_admin_account_path(account))
    end

    it 'creates an add-on that runs until the end of the base package' do
      package_end = account.current_account_package.ends_at

      post '/super_admin/account_addons', params: {
        account_addon: {
          account_id: account.id,
          addon_id: addon.id,
          start_date: Date.current,
          duration_type: 'until_package_end'
        }
      }

      expect(AccountAddon.last.ends_at).to eq(package_end)
    end

    it 'creates an add-on with a custom start/end date' do
      start_date = Date.current
      end_date = start_date.advance(days: 20)

      post '/super_admin/account_addons', params: {
        account_addon: {
          account_id: account.id,
          addon_id: addon.id,
          start_date: start_date,
          duration_type: 'custom',
          end_date: end_date
        }
      }

      account_addon = AccountAddon.last
      expect(account_addon.starts_at).to eq(start_date.beginning_of_day)
      expect(account_addon.ends_at.change(usec: 0)).to eq(end_date.end_of_day.change(usec: 0))
    end

    it 'rejects an add-on for an account without a current package' do
      account_without_package = create(:account, :without_package)

      expect do
        post '/super_admin/account_addons', params: {
          account_addon: {
            account_id: account_without_package.id,
            addon_id: addon.id,
            start_date: Date.current,
            duration_type: 'custom',
            end_date: Date.current.advance(days: 20)
          }
        }
      end.not_to change(AccountAddon, :count)
    end

    it 'rejects an add-on whose period exceeds the base package end' do
      package_end = account.current_account_package.ends_at

      expect do
        post '/super_admin/account_addons', params: {
          account_addon: {
            account_id: account.id,
            addon_id: addon.id,
            start_date: package_end.to_date.advance(days: 1),
            duration_type: 'custom',
            end_date: package_end.to_date.advance(days: 10)
          }
        }
      end.not_to change(AccountAddon, :count)
    end

    it 'rejects an add-on whose period starts before the base package start' do
      package_start = account.current_account_package.starts_at

      expect do
        post '/super_admin/account_addons', params: {
          account_addon: {
            account_id: account.id,
            addon_id: addon.id,
            start_date: package_start.to_date.advance(days: -1),
            duration_type: 'custom',
            end_date: Date.current
          }
        }
      end.not_to change(AccountAddon, :count)
    end

    it 'rejects an inactive add-on' do
      inactive = create(:addon, name: 'Retired Add-on', status: :inactive)

      expect do
        post '/super_admin/account_addons', params: {
          account_addon: {
            account_id: account.id,
            addon_id: inactive.id,
            start_date: Date.current,
            duration_type: 'custom',
            end_date: Date.current.advance(days: 20)
          }
        }
      end.not_to change(AccountAddon, :count)
    end

    it 'rejects an add-on whose end date is before the start date' do
      expect do
        post '/super_admin/account_addons', params: {
          account_addon: {
            account_id: account.id,
            addon_id: addon.id,
            start_date: Date.current.advance(days: 5),
            duration_type: 'custom',
            end_date: Date.current
          }
        }
      end.not_to change(AccountAddon, :count)
    end
  end

  describe 'PATCH /super_admin/account_addons/:id' do
    before { sign_in(super_admin, scope: :super_admin) }

    it 'updates the add-on period' do
      account_addon = create(:account_addon, account: account, addon: addon)
      start_date = Date.current

      patch "/super_admin/account_addons/#{account_addon.id}", params: {
        account_addon: {
          account_id: account.id,
          addon_id: addon.id,
          start_date: start_date,
          duration_type: 'fixed_months',
          duration_months: 1
        }
      }

      expect(account_addon.reload).to have_attributes(
        starts_at: start_date.beginning_of_day,
        duration_type: 'fixed_months',
        duration_months: 1
      )
      expect(account_addon.reload.ends_at.change(usec: 0)).to eq(start_date.advance(months: 1).end_of_day.change(usec: 0))
    end
  end

  describe 'DELETE /super_admin/account_addons/:id' do
    before { sign_in(super_admin, scope: :super_admin) }

    it 'removes the add-on activation' do
      account_addon = create(:account_addon, account: account, addon: addon)

      expect { delete "/super_admin/account_addons/#{account_addon.id}" }.to change(AccountAddon, :count).by(-1)
    end
  end
end
