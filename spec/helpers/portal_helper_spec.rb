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
      expect(helper.thumbnail_bg_color('Joe')).to eq('#6D95BA') # Length 3, so index is 0
      expect(helper.thumbnail_bg_color('John')).to eq('#A4C3C3') # Length 4, so index is 1
      expect(helper.thumbnail_bg_color('Jane james')).to eq('#A4C3C3') # Length 10, so index is 1
      expect(helper.thumbnail_bg_color('Jane_123')).to eq('#E19191') # Length 8, so index is 2
      expect(helper.thumbnail_bg_color('AlexanderTheGreat')).to eq('#E19191') # Length 17, so index is 2
      expect(helper.thumbnail_bg_color('Reginald John Sans')).to eq('#6D95BA') # Length 18, so index is 0
    end
  end
end
