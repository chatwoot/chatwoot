require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
describe 'CORS and cross-origin embed headers configuration' do
  # rubocop:enable RSpec/DescribeClass
  let(:app) { ->(_env) { [200, {}, ['ok']] } }

  describe 'CrossOriginEmbedHeaders.allowed_origins' do
    it 'is empty when CW_ALLOWED_EMBED_ORIGINS is unset' do
      with_modified_env CW_ALLOWED_EMBED_ORIGINS: nil do
        expect(CrossOriginEmbedHeaders.allowed_origins).to eq([])
      end
    end

    it 'parses a comma-separated list, trimming whitespace and dropping blanks' do
      with_modified_env CW_ALLOWED_EMBED_ORIGINS: 'https://a.example.com, https://b.example.com ,, ' do
        expect(CrossOriginEmbedHeaders.allowed_origins).to eq(['https://a.example.com', 'https://b.example.com'])
      end
    end
  end

  describe 'CrossOriginEmbedHeaders.cross_origin_isolation?' do
    it 'is false by default' do
      with_modified_env CW_ENABLE_CROSS_ORIGIN_ISOLATION: nil do
        expect(CrossOriginEmbedHeaders.cross_origin_isolation?).to be false
      end
    end

    it 'is true when the env var is a truthy value' do
      with_modified_env CW_ENABLE_CROSS_ORIGIN_ISOLATION: 'true' do
        expect(CrossOriginEmbedHeaders.cross_origin_isolation?).to be true
      end
    end
  end

  describe 'CrossOriginEmbedHeaders#call' do
    it 'leaves responses untouched when neither env var is set' do
      with_modified_env CW_ALLOWED_EMBED_ORIGINS: nil, CW_ENABLE_CROSS_ORIGIN_ISOLATION: nil do
        _, headers, = CrossOriginEmbedHeaders.new(app).call({})
        expect(headers).not_to include('content-security-policy', 'cross-origin-embedder-policy', 'cross-origin-resource-policy')
      end
    end

    it 'emits frame-ancestors when CW_ALLOWED_EMBED_ORIGINS is set' do
      with_modified_env CW_ALLOWED_EMBED_ORIGINS: 'https://a.example.com,https://b.example.com' do
        _, headers, = CrossOriginEmbedHeaders.new(app).call({})
        expect(headers['content-security-policy']).to eq("frame-ancestors 'self' https://a.example.com https://b.example.com;")
      end
    end

    it 'emits COEP and CORP when CW_ENABLE_CROSS_ORIGIN_ISOLATION is true' do
      with_modified_env CW_ENABLE_CROSS_ORIGIN_ISOLATION: 'true' do
        _, headers, = CrossOriginEmbedHeaders.new(app).call({})
        expect(headers['cross-origin-embedder-policy']).to eq('credentialless')
        expect(headers['cross-origin-resource-policy']).to eq('cross-origin')
      end
    end

    it 'does not emit frame-ancestors on its own when only isolation is enabled' do
      with_modified_env CW_ALLOWED_EMBED_ORIGINS: nil, CW_ENABLE_CROSS_ORIGIN_ISOLATION: 'true' do
        _, headers, = CrossOriginEmbedHeaders.new(app).call({})
        expect(headers).not_to have_key('content-security-policy')
      end
    end
  end
end
