# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/mailers/administrator_notifications/shared/smtp_config_shared.rb'

RSpec.describe AdministratorNotifications::ChannelNotificationsMailer do
  include_context 'with smtp config'

  let(:class_instance) { described_class.new }
  let!(:account) { create(:account) }
  let!(:administrator) { create(:user, :administrator, email: 'agent1@example.com', account: account) }

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
        expect(mail.to).to eq([administrator.email])
      end
    end
  end

  describe 'whatsapp_disconnect' do
    let!(:whatsapp_channel) do
      ch = build(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
      # Explicitly bypass validation to prevent provider config validation errors
      ch.define_singleton_method(:validate_provider_config) { true }
      # Prevent sync_templates from being called
      ch.define_singleton_method(:sync_templates) { nil }
      
      # Mock the provider_config_object to prevent webhook token generation issues
      mock_config = double('MockProviderConfig')
      allow(mock_config).to receive(:webhook_verify_token).and_return('test_webhook_token')
      allow(mock_config).to receive(:validate_config?).and_return(true)
      allow(mock_config).to receive(:cleanup_on_destroy)
      allow(mock_config).to receive(:api_key).and_return('test_api_key')
      allow(ch).to receive(:provider_config_object).and_return(mock_config)
      
      ch.save!(validate: false)
      ch
    end
    let!(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
    let(:mail) { described_class.with(account: account).whatsapp_disconnect(whatsapp_inbox).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('Your Whatsapp connection has expired')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([administrator.email])
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
      expect(mail.to).to eq([administrator.email])
    end
  end
end
