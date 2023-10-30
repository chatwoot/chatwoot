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
        expected_bg = 'background: url(/assets/images/hc/hexagon-dark.svg) color-mix(in srgb, #ff0000 20%, black)'
        expect(helper.generate_portal_bg('#ff0000', 'dark')).to eq(expected_bg)
      end
    end

    context 'when theme is not dark' do
      it 'returns the correct background with light grid image and color mix with white' do
        expected_bg = 'background: url(/assets/images/hc/hexagon-light.svg) color-mix(in srgb, #ff0000 20%, white)'
        expect(helper.generate_portal_bg('#ff0000', 'light')).to eq(expected_bg)
      end
    end

    context 'when provided with various colors' do
      it 'adjusts the background appropriately for dark theme' do
        expected_bg = 'background: url(/assets/images/hc/hexagon-dark.svg) color-mix(in srgb, #00ff00 20%, black)'
        expect(helper.generate_portal_bg('#00ff00', 'dark')).to eq(expected_bg)
      end

      it 'adjusts the background appropriately for light theme' do
        expected_bg = 'background: url(/assets/images/hc/hexagon-light.svg) color-mix(in srgb, #0000ff 20%, white)'
        expect(helper.generate_portal_bg('#0000ff', 'light')).to eq(expected_bg)
      end
    end
  end

  describe '#get_theme_names' do
    it 'returns the light theme name' do
      expect(helper.get_theme_names('light')).to eq(I18n.t('public_portal.header.appearance.light'))
    end

    it 'returns the dark theme name' do
      expect(helper.get_theme_names('dark')).to eq(I18n.t('public_portal.header.appearance.dark'))
    end

    it 'returns the system theme name for any other value' do
      expect(helper.get_theme_names('any_other_value')).to eq(I18n.t('public_portal.header.appearance.system'))
    end
  end

  describe '#get_theme_icon' do
    it 'returns the light theme icon' do
      expect(helper.get_theme_icon('light')).to eq('icons/sun')
    end

    it 'returns the dark theme icon' do
      expect(helper.get_theme_icon('dark')).to eq('icons/moon')
    end

    it 'returns the system theme icon for any other value' do
      expect(helper.get_theme_icon('any_other_value')).to eq('icons/monitor')
    end
  end

  describe '#generate_gradient_to_bottom' do
    context 'when theme is dark' do
      it 'returns the correct background gradient' do
        expected_gradient = 'background-image: linear-gradient(to bottom, transparent, #151718)'
        expect(helper.generate_gradient_to_bottom('dark')).to eq(expected_gradient)
      end
    end

    context 'when theme is not dark' do
      it 'returns the correct background gradient' do
        expected_gradient = 'background-image: linear-gradient(to bottom, transparent, white)'
        expect(helper.generate_gradient_to_bottom('light')).to eq(expected_gradient)
      end
    end
  end

  describe '#generate_article_link' do
    context 'when theme is not present' do
      it 'returns the correct link' do
        expect(helper.generate_article_link('portal_slug', 'article_slug', nil)).to eq(
          '/hc/portal_slug/articles/article_slug'
        )
      end
    end

    context 'when theme is present' do
      it 'returns the correct link' do
        expect(helper.generate_article_link('portal_slug', 'article_slug', 'dark')).to eq(
          '/hc/portal_slug/articles/article_slug?theme=dark'
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
end
