require 'rails_helper'

RSpec.describe Agents::DestroyJob do
  describe '#perform' do
    it 'clears company ownership only for the account the user is removed from' do
      account = create(:account)
      other_account = create(:account)
      user = create(:user, account: account)
      create(:account_user, account: other_account, user: user)
      owned_company = create(:company, account: account, account_owner: user)
      other_company = create(:company, account: other_account, account_owner: user)

      described_class.perform_now(account, user)

      expect(owned_company.reload.account_owner).to be_nil
      expect(other_company.reload.account_owner).to eq(user)
    end
  end
end
