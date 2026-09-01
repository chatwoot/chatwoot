require 'rails_helper'

RSpec.describe Cdn do
  describe '.asset_url' do
    context 'when ASSET_CDN_HOST is unset' do
      it 'returns the path unchanged' do
        with_modified_env ASSET_CDN_HOST: nil do
          expect(described_class.asset_url('/assets/foo.png')).to eq('/assets/foo.png')
        end
      end
    end

    context 'when ASSET_CDN_HOST is configured' do
      it 'prefixes the path with the CDN host' do
        with_modified_env ASSET_CDN_HOST: 'https://cdn.example.com' do
          expect(described_class.asset_url('/assets/foo.png')).to eq('https://cdn.example.com/assets/foo.png')
        end
      end

      it 'leaves absolute URLs unchanged' do
        with_modified_env ASSET_CDN_HOST: 'https://cdn.example.com' do
          expect(described_class.asset_url('https://other.example.com/foo.png')).to eq('https://other.example.com/foo.png')
          expect(described_class.asset_url('//cdn.example.org/foo.png')).to eq('//cdn.example.org/foo.png')
        end
      end

      it 'returns a blank path unchanged' do
        with_modified_env ASSET_CDN_HOST: 'https://cdn.example.com' do
          expect(described_class.asset_url(nil)).to be_nil
          expect(described_class.asset_url('')).to eq('')
        end
      end
    end

    context 'when ASSET_CDN_HOST has trailing slashes' do
      it 'dedupes the trailing slashes' do
        with_modified_env ASSET_CDN_HOST: 'https://cdn.example.com///' do
          expect(described_class.asset_url('/foo.png')).to eq('https://cdn.example.com/foo.png')
        end
      end
    end

    context 'when ASSET_CDN_HOST is whitespace-only' do
      it 'treats it as unset' do
        with_modified_env ASSET_CDN_HOST: '   ' do
          expect(described_class.asset_url('/foo.png')).to eq('/foo.png')
        end
      end
    end
  end

  describe '.normalize_logo_paths!' do
    it 'prefixes LOGO / LOGO_DARK / LOGO_THUMBNAIL when ASSET_CDN_HOST is set' do
      with_modified_env ASSET_CDN_HOST: 'https://cdn.example.com' do
        config = {
          'LOGO' => '/brand-assets/logo.svg',
          'LOGO_DARK' => '/brand-assets/logo_dark.svg',
          'LOGO_THUMBNAIL' => '/brand-assets/logo_thumbnail.svg',
          'BRAND_NAME' => 'Chatwoot'
        }
        described_class.normalize_logo_paths!(config)
        expect(config['LOGO']).to eq('https://cdn.example.com/brand-assets/logo.svg')
        expect(config['LOGO_DARK']).to eq('https://cdn.example.com/brand-assets/logo_dark.svg')
        expect(config['LOGO_THUMBNAIL']).to eq('https://cdn.example.com/brand-assets/logo_thumbnail.svg')
        expect(config['BRAND_NAME']).to eq('Chatwoot')
      end
    end

    it 'leaves values unchanged when ASSET_CDN_HOST is unset' do
      with_modified_env ASSET_CDN_HOST: nil do
        config = { 'LOGO_THUMBNAIL' => '/brand-assets/logo_thumbnail.svg' }
        described_class.normalize_logo_paths!(config)
        expect(config['LOGO_THUMBNAIL']).to eq('/brand-assets/logo_thumbnail.svg')
      end
    end

    it 'leaves admin-customized absolute URLs unchanged' do
      with_modified_env ASSET_CDN_HOST: 'https://cdn.example.com' do
        config = { 'LOGO' => 'https://customer.example.com/logo.svg' }
        described_class.normalize_logo_paths!(config)
        expect(config['LOGO']).to eq('https://customer.example.com/logo.svg')
      end
    end

    it 'skips missing or blank keys' do
      with_modified_env ASSET_CDN_HOST: 'https://cdn.example.com' do
        config = { 'LOGO' => '', 'LOGO_THUMBNAIL' => nil }
        expect { described_class.normalize_logo_paths!(config) }.not_to raise_error
        expect(config['LOGO']).to eq('')
        expect(config['LOGO_THUMBNAIL']).to be_nil
      end
    end
  end

  describe '.asset_url_or_origin' do
    context 'when ASSET_CDN_HOST is set' do
      it 'prefixes with the CDN host' do
        with_modified_env ASSET_CDN_HOST: 'https://cdn.example.com' do
          expect(described_class.asset_url_or_origin('/foo.png')).to eq('https://cdn.example.com/foo.png')
        end
      end
    end

    context 'when ASSET_CDN_HOST is unset' do
      it 'falls back to FRONTEND_URL' do
        with_modified_env ASSET_CDN_HOST: nil, FRONTEND_URL: 'https://app.example.com' do
          expect(described_class.asset_url_or_origin('/foo.png')).to eq('https://app.example.com/foo.png')
        end
      end
    end
  end
end
