require 'rails_helper'

RSpec.describe WebsiteBrandingService do
  describe '#perform' do
    let(:email) { 'user@example.com' }
    let(:url) { 'https://example.com' }
    let(:html_body) do
      <<~HTML
        <html lang="en">
        <head>
          <title>Acme Corp | Home</title>
          <meta property="og:site_name" content="Acme Corp" />
          <meta name="theme-color" content="#FF5733" />
          <link rel="icon" href="/favicon.ico" />
          <link rel="shortcut icon" href="/favicon-32.png" />
          <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
          <link rel="mask-icon" href="/safari-pinned-tab.svg" />
        </head>
        <body>
          <header>
            <a href="https://facebook.com/acmecorp">Facebook</a>
            <a href="https://instagram.com/acme_corp">Instagram</a>
          </header>
          <nav>
            <a href="https://facebook.com/acmecorp">FB</a>
            <a href="https://t.me/acmecorp">TG</a>
          </nav>
          <footer>
            <a href="https://facebook.com/acmecorp">Facebook</a>
            <a href="https://instagram.com/acme_corp">Instagram</a>
            <a href="https://wa.me/1234567890">WhatsApp</a>
            <a href="https://t.me/acmecorp">Telegram</a>
            <a href="https://tiktok.com/@acmetok">TikTok</a>
          </footer>
        </body>
        </html>
      HTML
    end

    before do
      stub_request(:get, url).to_return(status: 200, body: html_body, headers: { 'content-type' => 'text/html' })
    end

    it 'extracts basic brand info' do
      result = described_class.new(email).perform

      expect(result).to include(domain: 'example.com', title: 'Acme Corp', email: email,
                                description: nil, slogan: nil, is_nsfw: false, industries: [])
    end

    it 'extracts colors, logos, and socials' do
      result = described_class.new(email).perform

      expect(result[:colors]).to eq([{ hex: '#FF5733', name: nil }])
      expect(result[:logos].first[:url]).to eq('https://example.com/favicon.ico')
      expect(result[:socials].map { |s| s[:type] }).to contain_exactly('facebook', 'instagram', 'whatsapp', 'telegram', 'tiktok')
    end

    context 'when og:site_name is missing' do
      let(:html_body) do
        <<~HTML
          <html lang="fr">
          <head><title>Mon Entreprise - Bienvenue</title></head>
          <body></body>
          </html>
        HTML
      end

      it 'falls back to the first segment of the title' do
        result = described_class.new(email).perform
        expect(result[:title]).to eq('Mon Entreprise')
      end
    end

    context 'when the page fails to load' do
      before { stub_request(:get, url).to_return(status: 500, body: '') }

      it 'returns nil and sets http_status' do
        service = described_class.new(email)
        expect(service.perform).to be_nil
        expect(service.http_status).to eq(500)
      end
    end

    context 'when a network error occurs' do
      before { stub_request(:get, url).to_raise(StandardError.new('connection refused')) }

      it 'logs the error and returns nil' do
        expect(Rails.logger).to receive(:error).with(/connection refused/)
        expect(described_class.new(email).perform).to be_nil
      end
    end

    context 'when WhatsApp link uses api.whatsapp.com format' do
      let(:html_body) do
        <<~HTML
          <html lang="en">
          <head><title>Test</title></head>
          <body><a href="https://api.whatsapp.com/send?phone=5511999999999&text=Hello">Chat</a></body>
          </html>
        HTML
      end

      it 'extracts phone from query param' do
        result = described_class.new(email).perform
        whatsapp = result[:socials].find { |s| s[:type] == 'whatsapp' }
        expect(whatsapp[:url]).to eq('https://wa.me/5511999999999')
      end
    end

    context 'when links contain lookalike domains' do
      let(:html_body) do
        <<~HTML
          <html lang="en">
          <head><title>Test</title></head>
          <body>
            <a href="https://notfacebook.com/page">Not FB</a>
            <a href="https://fakeinstagram.com/user">Not IG</a>
          </body>
          </html>
        HTML
      end

      it 'does not match lookalike domains' do
        result = described_class.new(email).perform
        types = result[:socials].map { |s| s[:type] }
        expect(types).not_to include('facebook')
        expect(types).not_to include('instagram')
      end
    end

    context 'when favicon uses a relative path without leading slash' do
      let(:html_body) do
        <<~HTML
          <html lang="en">
          <head>
            <title>Test</title>
            <link rel="icon" href="favicon.ico" />
          </head>
          <body></body>
          </html>
        HTML
      end

      it 'resolves the relative favicon URL' do
        result = described_class.new(email).perform
        expect(result[:logos].first[:url]).to eq('https://example.com/favicon.ico')
      end
    end
  end
end
