require 'rails_helper'

RSpec.describe Integrations::GoogleTranslate::CredentialsValidator do
  let(:key) { { 'type' => 'service_account', 'client_email' => 'translate@example.iam.gserviceaccount.com', 'private_key' => 'key' } }
  let(:hook) { build(:integrations_hook, :google_translate, settings: { 'project_id' => 'test', 'credentials' => credentials }) }
  let(:client_class) { Google::Cloud::Translate::V3::TranslationService::Client }
  let(:google) { instance_double(client_class, detect_language: Google::Cloud::Translate::V3::DetectLanguageResponse.new) }
  let(:config) { OpenStruct.new }

  before do
    allow(client_class).to receive(:new).and_yield(config).and_return(google)
  end

  context 'with a service account key' do
    let(:credentials) { key.merge('token_uri' => 'https://accounts.google.com/o/oauth2/token') }

    it 'accepts the key when Google answers' do
      expect(described_class.valid?(hook)).to be(true)
      expect(config.credentials).to eq(key.merge('project_id' => 'test'))
    end

    it 'rejects the key when Google refuses it' do
      allow(google).to receive(:detect_language).and_raise(Signet::AuthorizationError, 'invalid_grant')

      expect(described_class.valid?(hook)).to be(false)
    end
  end

  context 'with another credential type' do
    let(:credentials) do
      { 'type' => 'external_account', 'credential_source' => { 'file' => 'unsupported' } }
    end

    it 'rejects the key without passing it to Google' do
      expect(described_class.valid?(hook)).to be(false)
      expect(client_class).not_to have_received(:new)
    end
  end

  context 'with a key field that is not a string' do
    let(:credentials) { key.merge('private_key' => ['key']) }

    it 'rejects the key without passing it to Google' do
      expect(described_class.valid?(hook)).to be(false)
      expect(client_class).not_to have_received(:new)
    end
  end

  context 'with a non-Google token URL' do
    let(:credentials) { key.merge('token_uri' => 'https://example.test/token') }

    it 'rejects the key without constructing a Google client' do
      expect(described_class.valid?(hook)).to be(false)
      expect(client_class).not_to have_received(:new)
    end
  end
end
