# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  let!(:user) { create(:user) }

  context 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:account_id) }
  end

  context 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inviter).class_name('User').required(false) }
    it { is_expected.to have_many(:assigned_conversations).class_name('Conversation').dependent(:nullify) }
    it { is_expected.to have_many(:inbox_members).dependent(:destroy) }
    it { is_expected.to have_many(:notification_settings).dependent(:destroy) }
    it { is_expected.to have_many(:assigned_inboxes).through(:inbox_members) }
    it { is_expected.to have_many(:messages) }
  end

  describe 'pubsub_token' do
    before { user.update(name: Faker::Name.name) }

    it { expect(user.pubsub_token).not_to eq(nil) }
    it { expect(user.saved_changes.keys).not_to eq('pubsub_token') }
  end

  describe 'notification_settings' do
    it 'gets created with the right default settings' do
      expect(user.notification_settings).not_to eq(nil)

      expect(user.notification_settings.first.conversation_creation?).to eq(false)
      expect(user.notification_settings.first.conversation_assignment?).to eq(true)
    end
  end
end
