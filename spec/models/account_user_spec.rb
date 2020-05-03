# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  let!(:account_user) { create(:account_user) }

  describe 'notification_settings' do
    it 'gets created with the right default settings' do
      expect(account_user.user.notification_settings).not_to eq(nil)

      expect(account_user.user.notification_settings.first.email_conversation_creation?).to eq(false)
      expect(account_user.user.notification_settings.first.email_conversation_assignment?).to eq(true)
    end
  end
end
