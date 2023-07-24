# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdministratorNotifications::ChannelNotificationsMailer do
  let(:class_instance) { described_class.new }
  let!(:account) { create(:account) }
  let!(:administrator) { create(:user, :administrator, email: 'agent1@example.com', account: account) }

  before do
    allow(described_class).to receive(:new).and_return(class_instance)
    allow(class_instance).to receive(:smtp_config_set_or_development?).and_return(true)
    Account::ContactsExportJob.perform_now(account.id, [])
  end

  describe 'slack_disconnect' do
    let(:mail) { described_class.with(account: account).slack_disconnect.deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('Your Slack integration has expired')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([administrator.email])
    end
  end

  describe 'facebook_disconnect' do
    before do
      stub_request(:post, /graph.facebook.com/)
    end

    let!(:facebook_channel) { create(:channel_facebook_page, account: account) }
    let!(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: account) }
    let(:mail) { described_class.with(account: account).facebook_disconnect(facebook_inbox).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('Your Facebook page connection has expired')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([administrator.email])
    end
  end

  describe 'whatsapp_disconnect' do
    let!(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }
    let!(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
    let(:mail) { described_class.with(account: account).whatsapp_disconnect(whatsapp_inbox).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('Your Whatsapp connection has expired')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([administrator.email])
    end
  end

  describe 'contact_export_complete' do
    let!(:file_url) { Rails.application.routes.url_helpers.rails_blob_url(account.contacts_export) }
    let(:mail) { described_class.with(account: account).contact_export_complete(file_url).deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq("Your contact's export file is available to download.")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([administrator.email])
    end
  end
end
