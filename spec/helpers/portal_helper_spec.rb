require 'rails_helper'

describe PortalHelper do
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
