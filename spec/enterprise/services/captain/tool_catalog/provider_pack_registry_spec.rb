require 'rails_helper'

RSpec.describe Captain::ToolCatalog::ProviderPackRegistry do
  let(:example_pack_path) { Rails.root.join('spec/fixtures/captain/tool_catalog/providers/example') }

  it 'discovers, compiles, and finds provider packs by provider key' do
    Dir.mktmpdir do |directory|
      FileUtils.ln_s(example_pack_path, Pathname(directory).join('example'))
      registry = described_class.new(providers_path: directory)

      expect(registry.all.map { |pack| pack.dig('provider', 'key') }).to eq(['example'])
      expect(registry.find('example')).to equal(registry.all.first)
    end
  end

  it 'returns an empty catalog before production packs are added' do
    Dir.mktmpdir do |directory|
      expect(described_class.new(providers_path: directory).all).to eq([])
    end
  end

  it 'rejects duplicate provider keys across pack directories' do
    Dir.mktmpdir do |directory|
      FileUtils.ln_s(example_pack_path, Pathname(directory).join('first'))
      FileUtils.ln_s(example_pack_path, Pathname(directory).join('second'))
      registry = described_class.new(providers_path: directory)

      expect { registry.all }.to raise_error(Captain::ToolCatalog::ProviderPackError, 'Duplicate provider keys: example')
    end
  end

  it 'raises not found for an unknown provider without using it as a file path' do
    Dir.mktmpdir do |directory|
      registry = described_class.new(providers_path: directory)

      expect { registry.find('../../secrets') }.to raise_error(ActiveRecord::RecordNotFound, /Unknown Captain tool catalog provider/)
    end
  end
end
