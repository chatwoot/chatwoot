# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Saml::IdpMetadataService do
  let(:metadata_url) { 'https://idp.example.com/saml/v2/metadata' }
  let(:certificate) { build(:account_saml_settings).certificate }
  let(:rotated_certificate) { build(:account_saml_settings).certificate }
  let(:key_descriptors) { key_descriptor(certificate) }
  let(:sso_binding) { 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect' }
  let(:metadata_xml) do
    <<~XML
      <md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" entityID="https://idp.example.com/saml/v2/metadata">
        <md:IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
          #{key_descriptors}
          <md:SingleSignOnService Binding="#{sso_binding}" Location="https://idp.example.com/saml/v2/SSO"/>
        </md:IDPSSODescriptor>
      </md:EntityDescriptor>
    XML
  end

  def key_descriptor(pem)
    body = pem.gsub(/-----(BEGIN|END) CERTIFICATE-----|\s/, '')
    <<~XML
      <md:KeyDescriptor use="signing">
        <ds:KeyInfo><ds:X509Data><ds:X509Certificate>#{body}</ds:X509Certificate></ds:X509Data></ds:KeyInfo>
      </md:KeyDescriptor>
    XML
  end

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('idp.example.com').and_return(['93.184.216.34'])
    stub_request(:get, metadata_url).to_return(status: 200, body: metadata_xml, headers: { 'Content-Type' => 'application/xml' })
  end

  describe '#perform' do
    it 'returns the SSO URL, entity ID and signing certificate' do
      expect(described_class.new(metadata_url).perform).to eq(
        sso_url: 'https://idp.example.com/saml/v2/SSO',
        idp_entity_id: 'https://idp.example.com/saml/v2/metadata',
        certificate: certificate.strip
      )
    end

    context 'when the metadata lists two signing certificates' do
      let(:key_descriptors) { key_descriptor(certificate) + key_descriptor(rotated_certificate) }

      it 'returns both certificates' do
        expect(described_class.new(metadata_url).perform[:certificate]).to eq("#{certificate.strip}\n#{rotated_certificate.strip}")
      end
    end

    context 'when one of the signing certificates is malformed' do
      let(:key_descriptors) do
        malformed = "-----BEGIN CERTIFICATE-----\nbm90IGEgY2VydGlmaWNhdGU=\n-----END CERTIFICATE-----\n"
        key_descriptor(certificate) + key_descriptor(malformed)
      end

      it 'raises an error' do
        expect { described_class.new(metadata_url).perform }.to raise_error(described_class::Error)
      end
    end

    context 'when the metadata has no signing certificate' do
      let(:key_descriptors) { '' }

      it 'raises an error' do
        expect { described_class.new(metadata_url).perform }.to raise_error(described_class::Error)
      end
    end

    context 'when the metadata has no redirect SSO URL' do
      let(:sso_binding) { 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST' }

      it 'raises an error' do
        expect { described_class.new(metadata_url).perform }.to raise_error(described_class::Error)
      end
    end

    context 'when the response is not IdP metadata' do
      let(:metadata_xml) { '<html><body>Not found</body></html>' }

      it 'raises an error' do
        expect { described_class.new(metadata_url).perform }.to raise_error(described_class::Error)
      end
    end

    context 'when the fetch fails' do
      before { stub_request(:get, metadata_url).to_return(status: 500) }

      it 'raises an error' do
        expect { described_class.new(metadata_url).perform }.to raise_error(described_class::Error)
      end
    end

    context 'when the URL points to a private address' do
      before { allow(Resolv).to receive(:getaddresses).with('idp.example.com').and_return(['10.0.0.5']) }

      it 'raises an error' do
        expect { described_class.new(metadata_url).perform }.to raise_error(described_class::Error)
      end
    end
  end
end
