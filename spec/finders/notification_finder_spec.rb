require 'rails_helper'

describe NotificationFinder do
  subject(:notification_finder) { described_class.new(user, account, params) }

  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }

  before do
    create(:notification, account: account, user: user, updated_at: DateTime.now.utc + 1.day)
    create(:notification, account: account, user: user, snoozed_until: DateTime.now.utc + 3.days, updated_at: DateTime.now.utc)
    create(:notification, account: account, user: user, updated_at: DateTime.now.utc + 2.days)
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

    context 'when order by updated_at' do
      let(:params) { { status: 'open' } }

      it 'returns all notifications' do
        result = notification_finder.perform
        expect(result.first.updated_at).to be > result.last.updated_at
      end
    end
  end
end
