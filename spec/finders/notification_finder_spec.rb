require 'rails_helper'

describe NotificationFinder do
  subject(:notification_finder) { described_class.new(user, account, params) }

  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }

  before do
    create(:notification, account: account, user: user)
    create(:notification, account: account, user: user)
    create(:notification, account: account, user: user, snoozed_until: DateTime.now.utc + 1.day)
  end

  describe '#perform' do
    context 'with snoozed status' do
      let(:params) { { status: 'snoozed' } }

      it 'filter notifications by status' do
        result = notification_finder.perform
        expect(result.length).to be 1
      end
    end

    context 'without snoozed status' do
      let(:params) { { status: 'open' } }

      it 'returns all notifications' do
        result = notification_finder.perform
        expect(result.length).to be 3
      end
    end
  end
end
