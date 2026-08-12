require 'rails_helper'

RSpec.describe 'Super Admin Account Packages API', type: :request do
  let(:super_admin) { create(:super_admin) }
  let(:account) { create(:account, :without_package, status: :suspended) }
  let(:package) { create(:package) }

  before { sign_in(super_admin, scope: :super_admin) }

  describe 'GET /super_admin/account_packages/new' do
    it 'shows the assign package page with the available packages' do
      get "/super_admin/account_packages/new?account_id=#{account.id}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include(package.name)
      expect(response.body).to include(account.name)
    end
  end

  describe 'POST /super_admin/account_packages' do
    it 'assigns a package and activates the account' do
      expect do
        post '/super_admin/account_packages', params: {
          account_package: {
            account_id: account.id,
            package_id: package.id,
            starts_at: 1.day.ago,
            ends_at: 1.day.from_now
          }
        }
      end.to change(AccountPackage, :count).by(1)

      expect(account.reload).to be_active
    end

    it 'rejects an assignment whose end date is before the start date' do
      expect do
        post '/super_admin/account_packages', params: {
          account_package: {
            account_id: account.id,
            package_id: package.id,
            starts_at: 1.day.from_now,
            ends_at: 1.day.ago
          }
        }
      end.not_to change(AccountPackage, :count)

      expect(account.reload).to be_suspended
    end
  end

  describe 'DELETE /super_admin/account_packages/:id' do
    it 'removes the assignment and suspends the account' do
      assignment = create(:account_package, account: account, package: package)
      expect(account.reload).to be_active

      expect { delete "/super_admin/account_packages/#{assignment.id}" }.to change(AccountPackage, :count).by(-1)

      expect(account.reload).to be_suspended
    end
  end
end
