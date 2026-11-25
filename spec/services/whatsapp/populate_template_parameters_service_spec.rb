require 'rails_helper'

describe Whatsapp::PopulateTemplateParametersService do
  let(:service) { described_class.new }

  describe '#normalize_url' do
    it 'normalizes URLs with spaces' do
      url_with_spaces = 'https://example.com/path with spaces'
      normalized = service.send(:normalize_url, url_with_spaces)

      expect(normalized).to eq('https://example.com/path%20with%20spaces')
    end

    it 'handles URLs with special characters' do
      url = 'https://example.com/path?query=test value'
      normalized = service.send(:normalize_url, url)

      expect(normalized).to include('https://example.com/path')
      expect(normalized).not_to include(' ')
    end

    it 'returns valid URLs unchanged' do
      url = 'https://example.com/valid-path'
      normalized = service.send(:normalize_url, url)

      expect(normalized).to eq(url)
    end

    it 'leaves existing percent-escapes untouched' do
      url = 'https://scontent.whatsapp.net/v/image.jpg?oh=AA%3FBB%2FCC%3DDD&oe=6AA7FF50'
      normalized = service.send(:normalize_url, url)

      expect(normalized).to eq(url)
    end

    it 'escapes characters that are illegal in a URL instead of dropping them' do
      url = 'https://example.com/image.jpg?caption="quoted" <tag>'
      normalized = service.send(:normalize_url, url)

      expect(normalized).to eq('https://example.com/image.jpg?caption=%22quoted%22%20%3Ctag%3E')
    end

    # Brackets are legal in a host (IPv6) but not in a path, so the encoding has to be per component:
    # left literal, URI.parse rejects the whole URL.
    it 'escapes brackets in the path' do
      normalized = service.send(:normalize_url, 'https://example.com/album[1]/image.jpg')

      expect(normalized).to eq('https://example.com/album%5B1%5D/image.jpg')
      expect { URI.parse(normalized) }.not_to raise_error
    end

    it 'converts an internationalized host to punycode rather than percent-encoding it' do
      normalized = service.send(:normalize_url, 'https://exämple.com/image.jpg')

      expect(normalized).to eq('https://xn--exmple-cua.com/image.jpg')
    end

    it 'escapes a literal percent sign without touching real escapes' do
      normalized = service.send(:normalize_url, 'https://example.com/100%.jpg?caption=a%20b')

      expect(normalized).to eq('https://example.com/100%25.jpg?caption=a%20b')
      expect { URI.parse(normalized) }.not_to raise_error
    end

    it 'raises on a value that is not a URL at all' do
      expect { service.send(:normalize_url, '4::aW1hZ2UvcG5n:ARZopaque') }
        .to raise_error(ArgumentError, /Invalid URL format/)
    end
  end

  describe '#build_media_parameter' do
    context 'when URL contains spaces' do
      it 'normalizes the URL before building media parameter' do
        url_with_spaces = 'https://example.com/image with spaces.jpg'
        result = service.build_media_parameter(url_with_spaces, 'IMAGE')

        expect(result[:type]).to eq('image')
        expect(result[:image][:link]).to eq('https://example.com/image%20with%20spaces.jpg')
      end
    end

    context 'when URL contains special characters in query string' do
      it 'normalizes the URL correctly' do
        url = 'https://example.com/video.mp4?title=My Video'
        result = service.build_media_parameter(url, 'VIDEO', 'test_video')

        expect(result[:type]).to eq('video')
        expect(result[:video][:link]).not_to include(' ')
      end
    end

    context 'when URL is already valid' do
      it 'builds media parameter without changing URL' do
        url = 'https://example.com/document.pdf'
        result = service.build_media_parameter(url, 'DOCUMENT', 'test.pdf')

        expect(result[:type]).to eq('document')
        expect(result[:document][:link]).to eq(url)
        expect(result[:document][:filename]).to eq('test.pdf')
      end
    end

    context 'when URL is a signed CDN link' do
      # The sample media WhatsApp ships with a media-header template (`example.header_handle[0]`)
      # is a signed scontent.whatsapp.net URL. Altering a single character invalidates the
      # signature and Meta rejects the send with "131053 Media upload error".
      let(:signed_url) do
        'https://scontent.whatsapp.net/v/t61.29466-34/687978337_1877819652904222_3947872441013628230_n.jpg' \
          '?ccb=1-7&_nc_sid=8b1bef&_nc_ohc=_LhiCWLBrzYQ7kNvwFrXk8p&_nc_zt=28&_nc_ht=scontent.whatsapp.net' \
          '&edm=AH51TzQEAAAA&_nc_gid=ysYExIrCDgUE4FDs3klCZw&oh=01_Q5Aa5QFGrQ4wUBzIasmARcne_Gf1Wsylopz0baO3TAZNrrZK2g&oe=6AA7FF50'
      end

      it 'sends the link byte for byte' do
        result = service.build_media_parameter(signed_url, 'IMAGE')

        expect(result[:image][:link]).to eq(signed_url)
      end
    end

    context 'when URL is longer than a text parameter is allowed to be' do
      it 'keeps the whole URL instead of truncating it' do
        url = "https://example.com/image.jpg?signature=#{'a' * 1200}"
        result = service.build_media_parameter(url, 'IMAGE')

        expect(result[:image][:link]).to eq(url)
      end
    end

    context 'when URL exceeds the maximum length' do
      it 'raises instead of sending a truncated link' do
        url = "https://example.com/image.jpg?signature=#{'a' * 2000}"

        expect { service.build_media_parameter(url, 'IMAGE') }
          .to raise_error(ArgumentError, 'URL too long (max 2000 characters)')
      end
    end

    context 'when URL is blank' do
      it 'returns nil' do
        result = service.build_media_parameter('', 'IMAGE')

        expect(result).to be_nil
      end
    end
  end
end
