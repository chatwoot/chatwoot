require 'rails_helper'

RSpec.describe Integrations::Hook, type: :model do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:app_id) }
    it { is_expected.to validate_presence_of(:account_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'when trying to create multiple hooks for an app' do
    let(:account) { create(:account) }

    context 'when app allows multiple hooks' do
      it 'allows to create succesfully' do
        create(:integrations_hook, account: account, app_id: 'webhook')
        expect(build(:integrations_hook, account: account, app_id: 'webhook').valid?).to eq true
      end
    end

    context 'when app doesnot allow multiple hooks' do
      it 'throws invalid error' do
        create(:integrations_hook, account: account, app_id: 'slack')
        expect(build(:integrations_hook, account: account, app_id: 'slack').valid?).to eq false
      end
    end
  end
end
