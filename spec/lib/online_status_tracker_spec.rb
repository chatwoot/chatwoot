require 'rails_helper'

describe OnlineStatusTracker do
  let!(:account) { create(:account) }
  let!(:user1) { create(:user, account: account) }
  let!(:user2) { create(:user, account: account) }
  let!(:user3) { create(:user, account: account) }

  context 'when get_available_users' do
    before do
      described_class.update_presence(account.id, 'User', user1.id)
    end

    it 'returns only the online user ids with presence' do
      expect(described_class.get_available_users(account.id).keys).to contain_exactly(user1.id.to_s)
      expect(described_class.get_available_users(account.id).values).not_to include(user3.id)
    end

    it 'returns agents who have auto offline configured false' do
      user2.account_users.first.update(auto_offline: false)
      expect(described_class.get_available_users(account.id).keys).to contain_exactly(user1.id.to_s, user2.id.to_s)
    end
  end
end
