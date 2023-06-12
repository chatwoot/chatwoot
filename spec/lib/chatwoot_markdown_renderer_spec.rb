require 'rails_helper'
require 'chatwoot_markdown_renderer'

RSpec.describe ChatwootMarkdownRenderer, type: :model do
  let(:superscript_renderer) { instance_double(SuperscriptRenderer) }
  let(:renderer) { described_class.new(superscript_renderer) }
  let(:markdown_content) { 'This is a *test* content with markdown' }
  let(:doc) { instance_double('CommonMarker doc instance') }
  let(:html_content) { '<p>This is a <em>test</em> content with markdown</p>' }

  before do
    allow(CommonMarker).to receive(:render_doc).with(markdown_content, :DEFAULT).and_return(doc)
    allow(superscript_renderer).to receive(:render).with(doc).and_return(html_content)
  end

  describe '#render_article' do
    let(:rendered_content) { renderer.render_article(markdown_content) }

    it 'renders the markdown content to html' do
      expect(rendered_content.to_s).to eq(html_content)
    end

    it 'returns an html safe string' do
      expect(rendered_content).to be_html_safe
    end
  end
end
