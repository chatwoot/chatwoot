require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::SearchChatwootDocsService do
  let(:base_url) { 'https://docs.example.com/hc/user-guide' }
  let(:account) { create(:account, locale: 'en') }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:user) { create(:user, account: account) }
  let(:service) { described_class.new(assistant, user: user) }
  let(:query) { 'connect whatsapp & email?' }

  before do
    allow(GlobalConfig).to receive(:get_value).and_call_original
    allow(GlobalConfig).to receive(:get_value).with('CAPTAIN_CHATWOOT_DOCS_URL').and_return(base_url)
  end

  def stub_portal(locale, default_locale: 'en')
    stub_request(:get, "#{base_url}/#{locale}.json").to_return(body: { meta: { default_locale: default_locale } }.to_json)
  end

  def stub_search(locale, articles)
    stub_request(:get, "#{base_url}/#{locale}/articles.json").with(query: { query: query })
                                                             .to_return(body: { payload: articles }.to_json)
  end

  def stub_article(slug, body)
    stub_request(:get, "#{base_url}/articles/#{slug}.md").to_return(body: body)
  end

  def search_result(slug, title)
    { title: title, content: "Snippet of #{title}", link: "/hc/user-guide/articles/#{slug}" }
  end

  describe '#active?' do
    it 'is active when the docs URL is set' do
      expect(service.active?).to be true
    end

    it 'is inactive when the docs URL is blank' do
      allow(GlobalConfig).to receive(:get_value).with('CAPTAIN_CHATWOOT_DOCS_URL').and_return('')

      expect(service.active?).to be false
    end
  end

  describe '#execute' do
    it 'returns each article with its full link and its Markdown, cut to the length limit' do
      stub_portal('en')
      stub_search('en', [search_result('1-whatsapp', 'WhatsApp in Chatwoot'), search_result('2-email', 'Email channel')])
      stub_article('1-whatsapp', 'Connect your number.')
      stub_article('2-email', 'word ' * 4000)

      result = service.execute(query: query)

      expect(result).to include("Title: WhatsApp in Chatwoot\nURL: #{base_url}/articles/1-whatsapp\n\nConnect your number.")
      expect(result).to include("Title: Email channel\nURL: #{base_url}/articles/2-email")
      expect(result.split("\n---\n").last.length).to be < described_class::MAX_ARTICLE_CHARACTERS + 100
    end

    it "searches the account's locale and the portal's default locale, alternating their results" do
      account.update!(locale: 'pt_BR')
      stub_portal('pt_BR')
      stub_search('pt_BR', [search_result('10-pt-a', 'PT A'), search_result('11-pt-b', 'PT B')])
      stub_search('en', [search_result('20-en-a', 'EN A'), search_result('21-en-b', 'EN B')])
      %w[10-pt-a 20-en-a 11-pt-b].each { |slug| stub_article(slug, "Body of #{slug}") }

      titles = service.execute(query: query).scan(/^Title: (.+)$/).flatten

      expect(titles).to eq(['PT A', 'EN A', 'PT B'])
    end

    it 'keeps the default locale results when the account locale has no articles' do
      account.update!(locale: 'pt_BR')
      stub_portal('pt_BR')
      stub_search('pt_BR', [])
      stub_search('en', [search_result('20-en-a', 'EN A')])
      stub_article('20-en-a', 'English body')

      expect(service.execute(query: query)).to include('Title: EN A')
    end

    it 'says so when the search returns no articles' do
      stub_portal('en')
      stub_search('en', [])

      expect(service.execute(query: query)).to eq('The Chatwoot docs returned no articles.')
    end

    it 'does not fetch a link outside the configured portal' do
      stub_portal('en')
      stub_search('en', [{ title: 'Elsewhere', content: 'Snippet', link: 'https://attacker.example.com/articles/x' },
                         { title: 'Other portal', content: 'Other snippet', link: '/hc/other/articles/y' }])

      result = service.execute(query: query)

      expect(result).to include("Title: Elsewhere\nSummary: Snippet").and include("Title: Other portal\nSummary: Other snippet")
      expect(a_request(:get, /attacker|other/)).not_to have_been_made
    end

    it 'logs and returns a clean message when the docs cannot be reached' do
      stub_portal('en')
      stub_request(:get, "#{base_url}/en/articles.json").with(query: hash_including({})).to_timeout
      allow(Rails.logger).to receive(:error)

      expect(service.execute(query: query)).to eq(described_class::UNREACHABLE_MESSAGE)
      expect(Rails.logger).to have_received(:error).with(/search_chatwoot_docs failed/)
    end

    it 'returns the same message when the docs answer with an error or a page that is not JSON' do
      stub_portal('en')
      stub_request(:get, "#{base_url}/en/articles.json").with(query: hash_including({})).to_return(status: 302)

      expect(service.execute(query: query)).to eq(described_class::UNREACHABLE_MESSAGE)

      stub_request(:get, "#{base_url}/en/articles.json").with(query: hash_including({})).to_return(body: '<html></html>')

      expect(service.execute(query: query)).to eq(described_class::UNREACHABLE_MESSAGE)
    end
  end
end
