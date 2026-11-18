require 'rails_helper'

describe Whatsapp::CallPermissionTemplate do
  subject(:template) { described_class.new(channel) }

  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', account: account, validate_provider_config: false, sync_templates: false)
  end
  let(:provider_service) { instance_double(Whatsapp::Providers::WhatsappCloudService) }

  before { allow(channel).to receive(:provider_service).and_return(provider_service) }

  describe '#language' do
    it "uses the account's locale, under Meta's code where it differs" do
      { 'pt_BR' => 'pt_BR', 'de' => 'de', 'pt' => 'pt_PT', 'no' => 'nb', 'zh_TW' => 'zh_TW' }.each do |locale, code|
        account.update!(locale: locale)
        expect(template.language).to eq(code)
      end
    end

    it 'falls back to English, with the English default text, for a locale Meta has no templates in' do
      account.update!(locale: 'is')

      expect(template.language).to eq('en')
      expect(template.body).to eq(I18n.t('conversations.messages.whatsapp.call_permission_request_body', locale: :en))
    end
  end

  describe '#body and #name' do
    it "uses the inbox's permission request message, and names a changed message as a new template" do
      default_name = template.name
      channel.provider_config = channel.provider_config.merge('call_permission_request_body' => 'Can we call you about your order?')

      expect(template.body).to eq('Can we call you about your order?')
      expect(template.name).to start_with('chatwoot_call_permission_')
      expect(template.name).not_to eq(default_name)
    end
  end

  describe '#create!' do
    it 'creates the template at Meta and remembers it' do
      allow(provider_service).to receive(:create_call_permission_template).and_return(true)

      template.create!

      expect(provider_service).to have_received(:create_call_permission_template)
        .with(name: template.name, language: 'en', body: template.body)
      expect(described_class.new(channel.reload)).to be_created
    end

    it 'remembers nothing when Meta refuses it, so a later attempt creates it again' do
      allow(provider_service).to receive(:create_call_permission_template).and_return(false)

      template.create!

      expect(described_class.new(channel.reload)).not_to be_created
    end

    it 'does not create the same template twice' do
      allow(provider_service).to receive(:create_call_permission_template).and_return(true)
      template.create!

      described_class.new(channel).create!

      expect(provider_service).to have_received(:create_call_permission_template).once
    end
  end
end
