require 'rails_helper'

RSpec.describe ChatwootMarkdownRenderer do
  let(:markdown_content) { 'This is a *test* content with ^markdown^' }
  let(:plain_text_content) { 'This is a test content with markdown' }
  let(:doc) { instance_double(CommonMarker::Node) }
  let(:renderer) { described_class.new(markdown_content) }
  let(:markdown_renderer) { instance_double(CustomMarkdownRenderer) }
  let(:base_markdown_renderer) { instance_double(BaseMarkdownRenderer) }
  let(:html_content) { '<p>This is a <em>test</em> content with <sup>markdown</sup></p>' }

  before do
    allow(CommonMarker).to receive(:render_doc).with(markdown_content, :DEFAULT).and_return(doc)
    allow(CustomMarkdownRenderer).to receive(:new).and_return(markdown_renderer)
    allow(markdown_renderer).to receive(:render).with(doc).and_return(html_content)
  end

  describe '#render_article' do
    let(:rendered_content) { renderer.render_article }

    it 'renders the markdown content to html' do
      expect(rendered_content.to_s).to eq(html_content)
    end

    it 'returns an html safe string' do
      expect(rendered_content).to be_html_safe
    end
  end

  describe '#render_message' do
    let(:message_html_content) { '<p>This is a <em>test</em> content with ^markdown^</p>' }
    let(:rendered_message) { renderer.render_message }

    before do
      allow(CommonMarker).to receive(:render_html).with(markdown_content).and_return(message_html_content)
      allow(BaseMarkdownRenderer).to receive(:new).and_return(base_markdown_renderer)
      allow(base_markdown_renderer).to receive(:render).with(doc).and_return(message_html_content)
    end

    it 'renders the markdown message to html' do
      expect(rendered_message.to_s).to eq(message_html_content)
    end

    it 'returns an html safe string' do
      expect(rendered_message).to be_html_safe
    end
  end

  describe '#render_markdown_to_plain_text' do
    let(:rendered_content) { renderer.render_markdown_to_plain_text }

    before do
      allow(doc).to receive(:to_plaintext).and_return(plain_text_content)
    end

    it 'renders the markdown content to plain text' do
      expect(rendered_content).to eq(plain_text_content)
    end
  end
end
