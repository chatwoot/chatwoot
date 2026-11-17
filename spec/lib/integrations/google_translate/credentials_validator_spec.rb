require 'rails_helper'

RSpec.describe Integrations::GoogleTranslate::CredentialsValidator do
  let(:key) { { 'type' => 'service_account', 'client_email' => 'translate@example.iam.gserviceaccount.com', 'private_key' => 'key' } }
  let(:hook) { build(:integrations_hook, :google_translate, settings: { 'project_id' => 'test', 'credentials' => credentials }) }
  let(:google) { instance_double(Integrations::GoogleTranslate::ProcessorService, detect: 'en') }

  before do
    allow(Integrations::GoogleTranslate::ProcessorService).to receive(:new).and_return(google)
  end

  context 'with a service account key' do
    let(:credentials) { key }

    it 'accepts the key when Google answers' do
      expect(described_class.valid?(hook)).to be(true)
    end

    it 'rejects the key when Google refuses it' do
      allow(google).to receive(:detect).and_raise(Signet::AuthorizationError, 'invalid_grant')

      expect(described_class.valid?(hook)).to be(false)
    end
  end

  context 'with another credential type' do
    let(:credentials) do
      key.merge('type' => 'external_account', 'token_url' => 'https://attacker.example/token', 'credential_source' => { 'file' => '/etc/hosts' })
    end

    it 'rejects the key without passing it to Google' do
      expect(described_class.valid?(hook)).to be(false)
      expect(Integrations::GoogleTranslate::ProcessorService).not_to have_received(:new)
    end
  end

  context 'with a key field that is not a string' do
    let(:credentials) { key.merge('private_key' => ['key']) }

    it 'rejects the key without passing it to Google' do
      expect(described_class.valid?(hook)).to be(false)
      expect(Integrations::GoogleTranslate::ProcessorService).not_to have_received(:new)
    end
  end
end
