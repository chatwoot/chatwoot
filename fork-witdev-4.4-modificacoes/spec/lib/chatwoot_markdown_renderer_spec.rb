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
    before do
      allow(CommonMarker).to receive(:render_doc).with(markdown_content, :DEFAULT, [:table]).and_return(doc)
    end

    let(:rendered_content) { renderer.render_article }

    it 'renders the markdown content to html' do
      expect(rendered_content.to_s).to eq(html_content)
    end

    it 'returns an html safe string' do
      expect(rendered_content).to be_html_safe
    end

    context 'when tables in markdown' do
      let(:markdown_content) do
        <<~MARKDOWN
          This is a **bold** text and *italic* text.

          | Header1      | Header2      |
          | ------------ | ------------ |
          | **Bold Cell**| *Italic Cell*|
          | Cell3        | Cell4        |
        MARKDOWN
      end

      let(:html_content) do
        <<~HTML
          <p>This is a <strong>bold</strong> text and <em>italic</em> text.</p>
          <table>
            <thead>
              <tr><th>Header1</th><th>Header2</th></tr>
            </thead>
            <tbody>
              <tr><td><strong>Bold Cell</strong></td><td><em>Italic Cell</em></td></tr>
              <tr><td>Cell3</td><td>Cell4</td></tr>
            </tbody>
          </table>
        HTML
      end

      it 'renders tables in html' do
        expect(rendered_content.to_s).to eq(html_content)
      end
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
