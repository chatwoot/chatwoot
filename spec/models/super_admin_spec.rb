require 'rails_helper'

RSpec.describe SuperAdmin do
  describe 'account lockout' do
    let(:super_admin) { create(:super_admin) }

    it 'never locks after repeated failed authentications' do
      (Devise.maximum_attempts + 5).times do
        super_admin.valid_for_authentication? { false }
      end

      expect(super_admin.reload.access_locked?).to be false
      expect(super_admin.failed_attempts).to eq(0)
    end
  end
end
