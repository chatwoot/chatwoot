require 'rails_helper'

RSpec.describe Captain::ToolCatalog::ProviderPackLoader do
  subject(:load_provider_pack) { described_class.new(pack_path: pack_path).load }

  let(:providers_path) { Rails.root.join('spec/fixtures/captain/tool_catalog/providers') }

  context 'with a valid provider pack manifest' do
    let(:pack_path) { providers_path.join('example') }

    it 'loads the manifest using the catalog contract' do
      manifest = load_provider_pack

      expect(manifest).to include(
        'schema_version' => 1,
        'key' => 'example',
        'allowed_origins' => ['https://api.example.com']
      )
      expect(manifest.dig('templates', 0, 'recipe', 0, 'bindings', 'email')).to eq(
        'source' => 'contact',
        'path' => 'email'
      )
    end
  end

  context 'with a manifest that violates the contract' do
    let(:pack_path) { providers_path.join('invalid') }

    it 'raises a validation error without accepting partial definitions' do
      expect { load_provider_pack }
        .to raise_error(described_class::InvalidProviderPackError, /Invalid provider pack manifest/)
    end
  end

  context 'without a manifest' do
    let(:pack_path) { providers_path.join('missing') }

    it 'raises a specific missing-manifest error' do
      expect { load_provider_pack }
        .to raise_error(described_class::InvalidProviderPackError, 'Provider pack manifest not found: manifest.yml')
    end
  end
end
