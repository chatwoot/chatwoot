require 'rails_helper'

RSpec.describe Captain::ToolsManifest::GithubSource do
  let(:revision) { 'a' * 40 }
  let(:repository_url) { 'https://api.github.com/repos/chatwoot/support-tools' }
  let(:latest_commit_url) { "#{repository_url}/commits/HEAD" }

  before do
    stub_request(:get, latest_commit_url).with(headers: { 'Accept' => 'application/vnd.github.sha' }).to_return(status: 200, body: revision)
    stub_request(:get, repository_url).to_return(status: 200, body: { default_branch: 'main' }.to_json)
  end

  describe 'parsing' do
    it 'accepts an owner/repository/folder identifier' do
      source = described_class.new(' chatwoot/support-tools/shopify ')

      expect([source.repository, source.path]).to eq(['chatwoot/support-tools', 'shopify'])
    end

    it 'identifies the source in lowercase' do
      source = described_class.new('Chatwoot/Support-Tools/Shopify')

      expect([source.repository, source.path]).to eq(['chatwoot/support-tools', 'shopify'])
    end

    it 'accepts a GitHub folder URL' do
      source = described_class.new('https://github.com/chatwoot/support-tools/tree/main/shopify')

      expect([source.repository, source.path]).to eq(['chatwoot/support-tools', 'shopify'])
    end

    it 'accepts a GitHub manifest file URL' do
      source = described_class.new('https://github.com/chatwoot/support-tools/blob/main/shopify/toolset.yml')

      expect([source.repository, source.path]).to eq(['chatwoot/support-tools', 'shopify'])
    end

    it 'rejects unsupported sources' do
      ['chatwoot/support-tools', 'chatwoot/support-tools/..', 'https://gitlab.com/chatwoot/support-tools/tree/main/shopify',
       'http://github.com/chatwoot/support-tools/tree/main/shopify', 'https://github.com/chatwoot/support-tools',
       'https://github.com/chatwoot/support-tools/blob/main/shopify/README.md', nil].each do |source|
        expect { described_class.new(source) }.to raise_error(described_class::SourceError), "expected #{source.inspect} to be rejected"
      end
    end
  end

  describe '#latest_revision' do
    it 'returns the latest commit on the default branch' do
      expect(described_class.new('chatwoot/support-tools/shopify').latest_revision).to eq(revision)
    end

    it 'accepts a URL pointing at the default branch' do
      expect(described_class.new('https://github.com/chatwoot/support-tools/tree/main/shopify').latest_revision).to eq(revision)
    end

    it 'rejects a URL pointing at another branch' do
      source = described_class.new('https://github.com/chatwoot/support-tools/tree/feature/new-tools/shopify')

      expect { source.latest_revision }.to raise_error(described_class::SourceError, /default branch \(main\)/)
    end

    it 'looks up the commit without a token when none is configured' do
      described_class.new('chatwoot/support-tools/shopify').latest_revision

      expect(WebMock).to(have_requested(:get, latest_commit_url).with { |request| !request.headers.key?('Authorization') })
    end

    context 'with a GitHub token configured' do
      before { create(:installation_config, name: 'CAPTAIN_TOOLS_GITHUB_TOKEN', value: 'github_pat_valid') }

      it 'authenticates the lookup' do
        described_class.new('chatwoot/support-tools/shopify').latest_revision

        expect(WebMock).to have_requested(:get, latest_commit_url).with(headers: { 'Authorization' => 'Bearer github_pat_valid' })
      end

      it 'falls back to an unauthenticated lookup when GitHub rejects the token' do
        stub_request(:get, latest_commit_url)
          .with(headers: { 'Authorization' => 'Bearer github_pat_valid' })
          .to_return(status: 401, body: 'Bad credentials')

        expect(described_class.new('chatwoot/support-tools/shopify').latest_revision).to eq(revision)
        expect(WebMock).to(have_requested(:get, latest_commit_url).with { |request| !request.headers.key?('Authorization') })
      end
    end
  end

  describe '#manifest' do
    let(:manifest_url) { "https://raw.githubusercontent.com/chatwoot/support-tools/#{revision}/shopify/toolset.yml" }

    it 'downloads the manifest at the given commit without authentication' do
      create(:installation_config, name: 'CAPTAIN_TOOLS_GITHUB_TOKEN', value: 'github_pat_valid')
      stub_request(:get, manifest_url).to_return(status: 200, body: 'kind: captain_toolset')

      expect(described_class.new('chatwoot/support-tools/shopify').manifest(revision)).to eq('kind: captain_toolset')
      expect(WebMock).to(have_requested(:get, manifest_url).with { |request| !request.headers.key?('Authorization') })
    end

    it 'downloads the manifest from the folder as it was typed' do
      stub_request(:get, "https://raw.githubusercontent.com/chatwoot/support-tools/#{revision}/Shopify/toolset.yml")
        .to_return(status: 200, body: 'kind: captain_toolset')

      expect(described_class.new('Chatwoot/Support-Tools/Shopify').manifest(revision)).to eq('kind: captain_toolset')
    end

    it 'stops downloading a manifest larger than 256 KiB' do
      stub_request(:get, manifest_url).to_return(status: 200, body: 'a' * (256.kilobytes + 1))

      expect { described_class.new('chatwoot/support-tools/shopify').manifest(revision) }
        .to raise_error(described_class::SourceError, /larger than 256 KiB/)
    end

    it 'raises when the manifest cannot be fetched' do
      stub_request(:get, manifest_url).to_return(status: 404, body: 'Not Found')

      expect { described_class.new('chatwoot/support-tools/shopify').manifest(revision) }
        .to raise_error(described_class::SourceError, /Could not fetch/)
    end
  end
end
