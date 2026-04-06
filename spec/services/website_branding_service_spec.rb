require 'rails_helper'

RSpec.describe WebsiteBrandingService do
  describe '#perform' do
    let(:url) { 'https://example.com' }
    let(:html_body) do
      <<~HTML
        <html lang="en">
        <head>
          <title>Acme Corp | Home</title>
          <meta property="og:site_name" content="Acme Corp" />
          <meta property="og:image" content="https://example.com/og-image.png" />
          <meta name="theme-color" content="#FF5733" />
          <link rel="icon" href="/favicon.ico" />
        </head>
        <body>
          <header><a href="/">Home</a></header>
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

    it 'extracts business info, branding, and social handles' do
      result = described_class.new(url).perform

      expect(result).to eq({
                             business_name: 'Acme Corp',
                             language: 'en',
                             industry_category: nil,
                             social_handles: {
                               whatsapp: '1234567890',
                               line: nil,
                               facebook: 'acmecorp',
                               instagram: 'acme_corp',
                               telegram: 'acmecorp',
                               tiktok: '@acmetok'
                             },
                             branding: {
                               favicon: 'https://example.com/favicon.ico',
                               primary_color: '#FF5733'
                             }
                           })
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
        result = described_class.new(url).perform
        expect(result[:business_name]).to eq('Mon Entreprise')
        expect(result[:language]).to eq('fr')
      end
    end

    context 'when the page fails to load' do
      before { stub_request(:get, url).to_return(status: 500, body: '') }

      it 'returns nil' do
        expect(described_class.new(url).perform).to be_nil
      end
    end

    context 'when a network error occurs' do
      before { stub_request(:get, url).to_raise(StandardError.new('connection refused')) }

      it 'logs the error and returns nil' do
        expect(Rails.logger).to receive(:error).with(/connection refused/)
        expect(described_class.new(url).perform).to be_nil
      end
    end

    context 'when URL has no scheme' do
      before do
        stub_request(:get, 'https://example.com').to_return(status: 200, body: html_body, headers: { 'content-type' => 'text/html' })
      end

      it 'prepends https://' do
        result = described_class.new('example.com').perform
        expect(result[:business_name]).to eq('Acme Corp')
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
        result = described_class.new(url).perform
        expect(result[:social_handles][:whatsapp]).to eq('5511999999999')
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
        result = described_class.new(url).perform
        expect(result[:social_handles][:facebook]).to be_nil
        expect(result[:social_handles][:instagram]).to be_nil
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
        result = described_class.new(url).perform
        expect(result[:branding][:favicon]).to eq('https://example.com/favicon.ico')
      end
    end
  end
end
