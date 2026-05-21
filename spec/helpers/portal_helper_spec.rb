require 'rails_helper'

describe PortalHelper do
  describe '#generate_portal_bg_color' do
    context 'when theme is dark' do
      it 'returns the correct color mix with black' do
        expect(helper.generate_portal_bg_color('#ff0000', 'dark')).to eq(
          'color-mix(in srgb, #ff0000 20%, black)'
        )
      end
    end

    context 'when theme is not dark' do
      it 'returns the correct color mix with white' do
        expect(helper.generate_portal_bg_color('#ff0000', 'light')).to eq(
          'color-mix(in srgb, #ff0000 20%, white)'
        )
      end
    end

    context 'when provided with various colors' do
      it 'adjusts the color mix appropriately' do
        expect(helper.generate_portal_bg_color('#00ff00', 'dark')).to eq(
          'color-mix(in srgb, #00ff00 20%, black)'
        )
        expect(helper.generate_portal_bg_color('#0000ff', 'light')).to eq(
          'color-mix(in srgb, #0000ff 20%, white)'
        )
      end
    end
  end

  describe '#generate_portal_bg' do
    context 'when theme is dark' do
      it 'returns the correct background with dark grid image and color mix with black' do
        expected_bg = 'color-mix(in srgb, #ff0000 20%, black)'
        expect(helper.generate_portal_bg('#ff0000', 'dark')).to eq(expected_bg)
      end
    end

    context 'when theme is not dark' do
      it 'returns the correct background with light grid image and color mix with white' do
        expected_bg = 'color-mix(in srgb, #ff0000 20%, white)'
        expect(helper.generate_portal_bg('#ff0000', 'light')).to eq(expected_bg)
      end
    end

    context 'when provided with various colors' do
      it 'adjusts the background appropriately for dark theme' do
        expected_bg = 'color-mix(in srgb, #00ff00 20%, black)'
        expect(helper.generate_portal_bg('#00ff00', 'dark')).to eq(expected_bg)
      end

      it 'adjusts the background appropriately for light theme' do
        expected_bg = 'color-mix(in srgb, #0000ff 20%, white)'
        expect(helper.generate_portal_bg('#0000ff', 'light')).to eq(expected_bg)
      end
    end
  end

  describe '#generate_gradient_to_bottom' do
    context 'when theme is dark' do
      it 'returns the correct gradient' do
        expect(helper.generate_gradient_to_bottom('dark')).to eq(
          'linear-gradient(to bottom, transparent, #151718)'
        )
      end
    end

    context 'when theme is not dark' do
      it 'returns the correct gradient' do
        expect(helper.generate_gradient_to_bottom('light')).to eq(
          'linear-gradient(to bottom, transparent, white)'
        )
      end
    end

    context 'when provided with various colors' do
      it 'adjusts the gradient appropriately' do
        expect(helper.generate_gradient_to_bottom('dark')).to eq(
          'linear-gradient(to bottom, transparent, #151718)'
        )
        expect(helper.generate_gradient_to_bottom('light')).to eq(
          'linear-gradient(to bottom, transparent, white)'
        )
      end
    end
  end

  describe '#generate_portal_hover_color' do
    context 'when theme is dark' do
      it 'returns the correct color mix with #1B1B1B' do
        expect(helper.generate_portal_hover_color('#ff0000', 'dark')).to eq(
          'color-mix(in srgb, #ff0000 5%, #1B1B1B)'
        )
      end
    end

    context 'when theme is not dark' do
      it 'returns the correct color mix with #F9F9F9' do
        expect(helper.generate_portal_hover_color('#ff0000', 'light')).to eq(
          'color-mix(in srgb, #ff0000 5%, #F9F9F9)'
        )
      end
    end

    context 'when provided with various colors' do
      it 'adjusts the color mix appropriately' do
        expect(helper.generate_portal_hover_color('#00ff00', 'dark')).to eq(
          'color-mix(in srgb, #00ff00 5%, #1B1B1B)'
        )
        expect(helper.generate_portal_hover_color('#0000ff', 'light')).to eq(
          'color-mix(in srgb, #0000ff 5%, #F9F9F9)'
        )
      end
    end
  end

  describe '#theme_query_string' do
    context 'when theme is present and not system' do
      it 'returns the correct query string' do
        expect(helper.theme_query_string('dark')).to eq('?theme=dark')
      end
    end

    context 'when theme is not present' do
      it 'returns the correct query string' do
        expect(helper.theme_query_string(nil)).to eq('')
      end
    end

    context 'when theme is system' do
      it 'returns the correct query string' do
        expect(helper.theme_query_string('system')).to eq('')
      end
    end
  end

  describe '#generate_home_link' do
    context 'when theme is not present' do
      it 'returns the correct link' do
        expect(helper.generate_home_link('portal_slug', 'en', nil, true)).to eq(
          '/hc/portal_slug/en'
        )
      end
    end

    context 'when theme is present and plain layout is enabled' do
      it 'returns the correct link' do
        expect(helper.generate_home_link('portal_slug', 'en', 'dark', true)).to eq(
          '/hc/portal_slug/en?theme=dark'
        )
      end
    end

    context 'when plain layout is not enabled' do
      it 'returns the correct link' do
        expect(helper.generate_home_link('portal_slug', 'en', 'dark', false)).to eq(
          '/hc/portal_slug/en'
        )
      end
    end
  end

  describe '#generate_category_link' do
    context 'when theme is not present' do
      it 'returns the correct link' do
        expect(helper.generate_category_link(
                 portal_slug: 'portal_slug',
                 category_locale: 'en',
                 category_slug: 'category_slug',
                 theme: nil,
                 is_plain_layout_enabled: true
               )).to eq(
                 '/hc/portal_slug/en/categories/category_slug'
               )
      end
    end

    context 'when theme is present and plain layout is enabled' do
      it 'returns the correct link' do
        expect(helper.generate_category_link(
                 portal_slug: 'portal_slug',
                 category_locale: 'en',
                 category_slug: 'category_slug',
                 theme: 'dark',
                 is_plain_layout_enabled: true
               )).to eq(
                 '/hc/portal_slug/en/categories/category_slug?theme=dark'
               )
      end
    end

    context 'when plain layout is not enabled' do
      it 'returns the correct link' do
        expect(helper.generate_category_link(
                 portal_slug: 'portal_slug',
                 category_locale: 'en',
                 category_slug: 'category_slug',
                 theme: 'dark',
                 is_plain_layout_enabled: false
               )).to eq(
                 '/hc/portal_slug/en/categories/category_slug'
               )
      end
    end
  end

  describe '#generate_article_link' do
    context 'when theme is not present' do
      it 'returns the correct link' do
        expect(helper.generate_article_link('portal_slug', 'article_slug', nil, true)).to eq(
          '/hc/portal_slug/articles/article_slug'
        )
      end
    end

    context 'when theme is present and plain layout is enabled' do
      it 'returns the correct link' do
        expect(helper.generate_article_link('portal_slug', 'article_slug', 'dark', true)).to eq(
          '/hc/portal_slug/articles/article_slug?theme=dark'
        )
      end
    end

    context 'when plain layout is not enabled' do
      it 'returns the correct link' do
        expect(helper.generate_article_link('portal_slug', 'article_slug', 'dark', false)).to eq(
          '/hc/portal_slug/articles/article_slug'
        )
      end
    end
  end

  describe '#render_category_content' do
    let(:markdown_content) { 'This is a *test* markdown content' }
    let(:plain_text_content) { 'This is a test markdown content' }
    let(:renderer) { instance_double(ChatwootMarkdownRenderer) }

    before do
      allow(ChatwootMarkdownRenderer).to receive(:new).with(markdown_content).and_return(renderer)
      allow(renderer).to receive(:render_markdown_to_plain_text).and_return(plain_text_content)
    end

    it 'converts markdown to plain text' do
      expect(helper.render_category_content(markdown_content)).to eq(plain_text_content)
    end
  end

  describe '#thumbnail_bg_color' do
    it 'returns the correct color based on username length' do
      expect(helper.thumbnail_bg_color('')).to be_in(['#6D95BA', '#A4C3C3', '#E19191'])
      expect(helper.thumbnail_bg_color('Joe')).to eq('#6D95BA')
      expect(helper.thumbnail_bg_color('John')).to eq('#A4C3C3')
      expect(helper.thumbnail_bg_color('Jane james')).to eq('#A4C3C3')
      expect(helper.thumbnail_bg_color('Jane_123')).to eq('#E19191')
      expect(helper.thumbnail_bg_color('AlexanderTheGreat')).to eq('#E19191')
      expect(helper.thumbnail_bg_color('Reginald John Sans')).to eq('#6D95BA')
    end
  end

  describe '#set_og_image_url' do
    let(:portal_name) { 'Chatwoot Portal' }
    let(:title) { 'Welcome to Chatwoot' }

    context 'when CDN URL is present' do
      before do
        InstallationConfig.create!(name: 'OG_IMAGE_CDN_URL', value: 'https://cdn.example.com')
        InstallationConfig.create!(name: 'OG_IMAGE_CLIENT_REF', value: 'client-123')
      end

      it 'returns the composed OG image URL with correct params' do
        result = helper.set_og_image_url(portal_name, title)
        uri = URI.parse(result)
        expect(uri.path).to eq('/og')
        params = Rack::Utils.parse_query(uri.query)
        expect(params['clientRef']).to eq('client-123')
        expect(params['title']).to eq(title)
        expect(params['portalName']).to eq(portal_name)
      end
    end

    context 'when CDN URL is blank' do
      before do
        InstallationConfig.create!(name: 'OG_IMAGE_CDN_URL', value: '')
        InstallationConfig.create!(name: 'OG_IMAGE_CLIENT_REF', value: 'client-123')
      end

      it 'returns nil' do
        expect(helper.set_og_image_url(portal_name, title)).to be_nil
      end
    end
  end

  describe '#generate_portal_brand_url' do
    it 'builds URL with UTM params and referer host as source (happy path)' do
      result = helper.generate_portal_brand_url('https://brand.example.com', 'https://app.chatwoot.com/some/page')
      uri = URI.parse(result)
      params = Rack::Utils.parse_query(uri.query)
      expect(uri.scheme).to eq('https')
      expect(uri.host).to eq('brand.example.com')
      expect(params['utm_medium']).to eq('helpcenter')
      expect(params['utm_campaign']).to eq('branding')
      expect(params['utm_source']).to eq('app.chatwoot.com')
    end

    it 'returns utm string when brand_url is nil or empty' do
      expect(helper.generate_portal_brand_url(nil,
                                              'https://app.chatwoot.com')).to eq(
                                                '?utm_campaign=branding&utm_medium=helpcenter&utm_source=app.chatwoot.com'
                                              )
      expect(helper.generate_portal_brand_url('',
                                              'https://app.chatwoot.com')).to eq(
                                                '?utm_campaign=branding&utm_medium=helpcenter&utm_source=app.chatwoot.com'
                                              )
    end

    it 'omits utm_source when referer is nil or invalid' do
      r1 = helper.generate_portal_brand_url('https://brand.example.com', nil)
      p1 = Rack::Utils.parse_query(URI.parse(r1).query)
      expect(p1.key?('utm_source')).to be(false)

      r2 = helper.generate_portal_brand_url('https://brand.example.com', '::not-a-valid-url')
      p2 = Rack::Utils.parse_query(URI.parse(r2).query)
      expect(p2.key?('utm_source')).to be(false)
      expect(p2['utm_medium']).to eq('helpcenter')
      expect(p2['utm_campaign']).to eq('branding')
    end
  end
end
