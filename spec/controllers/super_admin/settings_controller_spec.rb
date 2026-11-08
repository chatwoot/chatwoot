require 'rails_helper'

RSpec.describe 'Super Admin settings API', type: :request do
  let(:super_admin) { create(:super_admin) }

  describe 'GET /super_admin/settings/refresh' do
    before { sign_in(super_admin, scope: :super_admin) }

    it 'confirms the refresh when hub was reached' do
      allow(Internal::CheckNewVersionsJob).to receive(:perform_now).with(refresh_billing: true).and_return(true)

      get '/super_admin/settings/refresh'

      expect(response).to redirect_to(super_admin_settings_path)
      expect(flash[:notice]).to eq(I18n.t('super_admin.settings.refresh_succeeded'))
    end

    it 'says hub could not be reached when the sync failed' do
      allow(Internal::CheckNewVersionsJob).to receive(:perform_now).with(refresh_billing: true).and_return(false)

      get '/super_admin/settings/refresh'

      expect(response).to redirect_to(super_admin_settings_path)
      expect(flash[:alert]).to eq(I18n.t('super_admin.settings.refresh_failed'))
      expect(flash[:notice]).to be_nil
    end
  end
end
