require 'rails_helper'

RSpec.describe Integrations::GoogleServiceAccountCredentials do
  let(:key) do
    attributes_for(:integrations_hook, :dialogflow).fetch(:settings).fetch(:credentials).stringify_keys
  end

  describe '.for_client' do
    it 'accepts Google service account metadata and strips it before authentication' do
      credentials = key.merge(
        'auth_uri' => 'https://accounts.google.com/o/oauth2/auth',
        'token_uri' => 'https://oauth2.googleapis.com/token',
        'auth_provider_x509_cert_url' => 'https://www.googleapis.com/oauth2/v1/certs',
        'client_x509_cert_url' => 'https://www.googleapis.com/robot/v1/metadata/x509/dialogflow%40test.iam.gserviceaccount.com',
        'universe_domain' => 'googleapis.com'
      )

      expect(described_class.for_client(credentials, fallback_project_id: 'other-project')).to eq(key)
      legacy_credentials = credentials.merge('token_uri' => 'https://accounts.google.com/o/oauth2/token').except('universe_domain')
      expect(described_class.for_client(legacy_credentials)).to eq(key)
    end

    it 'uses the configured project if an older key omits its project ID' do
      credentials = key.except('project_id')
      result = described_class.for_client(credentials, fallback_project_id: 'configured-project')

      expect(result).to eq(key.merge('project_id' => 'configured-project'))
      expect(described_class.for_client(credentials)).to be_nil
    end

    {
      'credential_source' => { 'file' => 'unsupported' },
      'token_url' => 'https://example.test/token',
      'token_uri' => 'https://oauth2.googleapis.com.example.test/token',
      'auth_uri' => 'http://accounts.google.com/o/oauth2/auth',
      'auth_provider_x509_cert_url' => 'https://www.googleapis.com:8443/oauth2/v1/certs',
      'client_x509_cert_url' => 'https://example.test/certs',
      'universe_domain' => 'example.test'
    }.each do |field, value|
      it "rejects an unsupported #{field}" do
        credentials = key.merge(field => value)

        expect(described_class.for_client(credentials)).to be_nil
      end
    end

    it 'rejects a credential file path' do
      expect(described_class.for_client('credentials.json')).to be_nil
    end
  end
end
