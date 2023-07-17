require 'rails_helper'

RSpec.describe ChatwootMarkdownRenderer do
  let(:markdown_content) { 'This is a *test* content with ^markdown^' }
  let(:doc) { instance_double(CommonMarker::Node) }
  let(:renderer) { described_class.new(markdown_content) }
  let(:markdown_renderer) { instance_double(CustomMarkdownRenderer) }
  let(:html_content) { '<p>This is a <em>test</em> content with <sup>markdown</sup></p>' }

  describe '#render_article' do
    before do
      allow(CommonMarker).to receive(:render_doc).with(markdown_content, :DEFAULT).and_return(doc)
      allow(CustomMarkdownRenderer).to receive(:new).and_return(markdown_renderer)
      allow(markdown_renderer).to receive(:render).with(doc).and_return(html_content)
    end

    context 'when rendering a article' do
      let(:rendered_content) { renderer.render_article }

      it 'renders the markdown content to html' do
        expect(rendered_content.to_s).to eq(html_content)
      end

      it 'returns an html safe string' do
        expect(rendered_content).to be_html_safe
      end
    end

    context 'when rendering a message' do
      let(:message_html_content) { '<p>This is a <em>test</em> content with ^markdown^</p>' }
      let(:rendered_message) { renderer.render_message }

      before do
        allow(CommonMarker).to receive(:render_html).with(markdown_content).and_return(message_html_content)
      end

      it 'renders the markdown message to html' do
        expect(rendered_message.to_s).to eq(message_html_content)
      end

      it 'returns an html safe string' do
        expect(rendered_message).to be_html_safe
      end
    end
  end

  describe '#remove_empty_headers' do
    it 'removes headers with no subheaders or content' do
      payload = "# Empty Header\n\n# Header 1\n\nSome content\n\n# Header 2\n\nSome more content"
      renderer = described_class.new(payload)
      expect(renderer.remove_empty_headers).to eq("# Header 1\n\nSome content\n\n# Header 2\n\nSome more content")
    end

    it 'does not remove headers with subheaders' do
      payload = "# Header 1\n\n## Subheader\n\nSome content"
      renderer = described_class.new(payload)
      expect(renderer.remove_empty_headers).to eq(payload)
    end

    it 'does not remove headers with content' do
      payload = "# Header 1\n\nSome content\n\n# Header 2\n\nSome more content"
      renderer = described_class.new(payload)
      expect(renderer.remove_empty_headers).to eq(payload)
    end

    it 'does not remove headers with subheaders and content' do
      payload = "# Header 1\n\n## Subheader\n\nSome content\n\n# Header 2\n\nSome more content"
      renderer = described_class.new(payload)
      expect(renderer.remove_empty_headers).to eq(payload)
    end
  end
end
