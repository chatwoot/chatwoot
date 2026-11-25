# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationSetting do
  context 'with associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'internal chat push backfill' do
    let(:account) { create(:account) }
    let(:untouched) { create(:account_user, account: account).user.notification_settings.first }
    let(:chose_mentions_only) { create(:account_user, account: account).user.notification_settings.first }
    let(:turned_push_off) { create(:account_user, account: account).user.notification_settings.first }

    before do
      untouched.update!(selected_push_flags: [:push_conversation_assignment])
      chose_mentions_only.update!(selected_push_flags: [:push_internal_chat_mention])
      turned_push_off.update!(selected_push_flags: [])
    end

    it 'turns on internal chat push for users who never set it, keeping their other flags, every partial choice and push turned off' do
      require Rails.root.join('db/migrate/20261009120000_enable_internal_chat_push_for_existing_users.rb')

      ActiveRecord::Migration.suppress_messages { EnableInternalChatPushForExistingUsers.new.migrate(:up) }

      expect(untouched.reload.selected_push_flags).to contain_exactly(
        :push_conversation_assignment, :push_internal_chat_mention, :push_internal_chat_new_message
      )
      expect(chose_mentions_only.reload.selected_push_flags).to contain_exactly(:push_internal_chat_mention)
      expect(turned_push_off.reload.selected_push_flags).to be_empty
    end
  end
end
