# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  let!(:account_user) { create(:account_user) }
  let(:agent_destroy_service) { double }

  before do
    allow(Agents::DestroyService).to receive(:new).and_return(agent_destroy_service)
    allow(agent_destroy_service).to receive(:perform).and_return(agent_destroy_service)
  end

  describe 'notification_settings' do
    it 'gets created with the right default settings' do
      expect(account_user.user.notification_settings).not_to be_nil

      expect(account_user.user.notification_settings.first.email_conversation_creation?).to be(false)
      expect(account_user.user.notification_settings.first.email_conversation_assignment?).to be(true)
    end
  end

  describe 'destroy call agent::destroy service' do
    it 'gets created with the right default settings' do
      user = account_user.user
      account = account_user.account
      account_user.destroy!
      expect(Agents::DestroyService).to have_received(:new).with({
                                                                   user: user, account: account
                                                                 })
    end
  end
end
