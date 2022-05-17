# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AgentNotifications::ChannelNotificationMailer, type: :mailer do
  let(:class_instance) { described_class.new }
  let!(:account) { create(:account) }
  let!(:administrator) { create(:user, :administrator, email: 'admin@example.com', account: account) }
  let!(:agent_1) { create(:user, email: 'agent1@example.com', account: account) }
  let!(:agent_2) { create(:user, email: 'agent2@example.com', account: account) }

  before do
    allow(described_class).to receive(:new).and_return(class_instance)
    allow(class_instance).to receive(:smtp_config_set_or_development?).and_return(true)
  end

  describe 'facebook_disconnect' do
    before do
      stub_request(:post, /graph.facebook.com/)
    end

    let!(:facebook_channel) { create(:channel_facebook_page, account: account) }
    let!(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: account) }
    let(:inbox_member_1) { create(:inbox_member, inbox_id: facebook_inbox.id, user_id: administrator.id) }
    let!(:inbox_member_2) { create(:inbox_member, inbox_id: facebook_inbox.id, user_id: agent_1.id) }
    let!(:inbox_member_3) { create(:inbox_member, inbox_id: facebook_inbox.id, user_id: agent_2.id) }

    let(:mail) { described_class.with(account: account).facebook_disconnect(facebook_inbox).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('Your Facebook page connection has expired')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([inbox_member_2.user.email, inbox_member_3.user.email])
    end
  end
end
