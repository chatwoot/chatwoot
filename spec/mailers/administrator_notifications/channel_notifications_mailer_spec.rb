# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/mailers/administrator_notifications/shared/smtp_config_shared.rb'

RSpec.describe AdministratorNotifications::ChannelNotificationsMailer do
  include_context 'with smtp config'

  let(:class_instance) { described_class.new }
  let!(:account) { create(:account) }
  let!(:administrator) { create(:user, :administrator, email: 'agent1@example.com', account: account) }
  let!(:another_administrator) { create(:user, :administrator, email: 'agent2@example.com', account: account) }

  describe 'facebook_disconnect' do
    before do
      stub_request(:post, /graph.facebook.com/)
    end

    let!(:facebook_channel) { create(:channel_facebook_page, account: account) }
    let!(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: account) }

    context 'when sending the actual email' do
      let(:mail) { described_class.with(account: account).facebook_disconnect(facebook_inbox).deliver_now }

      it 'renders the subject' do
        expect(mail.subject).to eq('Your Facebook page connection has expired')
      end

      it 'renders the receiver email' do
        expect(mail.to).to contain_exactly(administrator.email, another_administrator.email)
      end
    end
  end

  describe 'whatsapp_disconnect' do
    let(:source) { 'embedded_signup' }
    let!(:whatsapp_channel) do
      create(
        :channel_whatsapp,
        provider: 'whatsapp_cloud',
        provider_config: {
          'api_key' => 'synthetic_access_token',
          'business_account_id' => 'synthetic_business_account_id',
          'phone_number_id' => 'synthetic_phone_number_id',
          'source' => 'embedded_signup'
        },
        sync_templates: false,
        validate_provider_config: false
      )
    end
    let!(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
    let(:mail) { described_class.with(account: account).whatsapp_disconnect(whatsapp_inbox).deliver_now }

    before do
      allow(whatsapp_inbox.channel).to receive(:provider_config)
        .and_return(whatsapp_channel.provider_config.merge('source' => source))
    end

    it 'renders the subject' do
      expect(mail.subject).to eq('Your WhatsApp connection needs to be refreshed')
    end

    it 'renders the receiver email' do
      expect(mail.to).to contain_exactly(administrator.email, another_administrator.email)
    end

    it 'links directly to the inbox configuration page' do
      expected_url = "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/settings/inboxes/#{whatsapp_inbox.id}/configuration"

      expect(mail.body.decoded).to include(expected_url)
    end

    it 'asks embedded signup inboxes to reconfigure' do
      expect(mail.body.decoded).to include('Please reconfigure the inbox')
    end

    context 'when the inbox uses manual setup' do
      let(:source) { nil }

      it 'asks the administrator to update the access token' do
        expect(mail.body.decoded).to include('Please update the inbox with a valid access token')
      end
    end
  end

  describe 'instagram_disconnect' do
    let!(:instagram_channel) { create(:channel_instagram, account: account) }
    let!(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account) }
    let(:mail) { described_class.with(account: account).instagram_disconnect(instagram_inbox).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('Your Instagram connection has expired')
    end

    it 'renders the receiver email' do
      expect(mail.to).to contain_exactly(administrator.email, another_administrator.email)
    end
  end
end
