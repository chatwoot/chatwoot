require 'rails_helper'

describe NotificationFinder do
  subject(:notification_finder) { described_class.new(user, account, params) }

  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }

  before do
    create(:notification, account: account, user: user, updated_at: DateTime.now.utc + 1.day, last_activity_at: DateTime.now.utc + 1.day)
    create(:notification, account: account, user: user, snoozed_until: DateTime.now.utc + 3.days, updated_at: DateTime.now.utc,
                          last_activity_at: DateTime.now.utc)
    create(:notification, account: account, user: user, updated_at: DateTime.now.utc + 2.days, last_activity_at: DateTime.now.utc + 2.days)
    create(:notification, account: account, user: user, updated_at: DateTime.now.utc + 4.days, last_activity_at: DateTime.now.utc + 4.days,
                          notification_type: :conversation_creation)
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
      let(:params) { {} }

      it 'returns all notifications' do
        result = notification_finder.perform
        expect(result.length).to be 3
      end
    end

    context 'when order by last_activity_at' do
      let(:params) { {} }

      it 'returns all notifications' do
        result = notification_finder.perform
        expect(result.first.last_activity_at).to be > result.last.last_activity_at
        expect(result.first.last_activity_at).to be > result.last.last_activity_at
      end
    end

    context 'when order by user notification settings' do
      let(:params) { {} }

      before do
        notification_setting = user.notification_settings.find_by(account_id: account.id)
        notification_setting.selected_email_flags = [:email_conversation_creation]
        notification_setting.save!
      end

      it 'returns all notifications' do
        result = notification_finder.perform
        expect(result.length).to be 4
      end
    end
  end
end
