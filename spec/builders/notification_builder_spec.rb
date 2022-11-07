require 'rails_helper'

describe ::NotificationBuilder do
  include ActiveJob::TestHelper

  describe '#perform' do
    let!(:account) { create(:account) }
    let!(:user) { create(:user, account: account) }
    let!(:primary_actor) { create(:conversation, account: account) }

    before do
      notification_setting = user.notification_settings.find_by(account_id: account.id)
      notification_setting.selected_email_flags = [:email_conversation_creation]
      notification_setting.save!
    end

    it 'creates a notification' do
      expect do
        described_class.new(
          notification_type: 'conversation_creation',
          user: user,
          account: account,
          primary_actor: primary_actor
        ).perform
      end.to change { user.notifications.count }.by(1)
    end

    it 'will not throw error if notification setting is not present' do
      user.account_users.destroy_all
      expect(
        described_class.new(
          notification_type: 'conversation_creation',
          user: user,
          account: account,
          primary_actor: primary_actor
        ).perform
      ).to be_nil
    end
  end
end
