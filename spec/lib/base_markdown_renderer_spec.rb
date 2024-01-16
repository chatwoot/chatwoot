require 'rails_helper'

describe BaseMarkdownRenderer do
  let(:renderer) { described_class.new }

  def render_markdown(markdown)
    doc = CommonMarker.render_doc(markdown, :DEFAULT)
    renderer.render(doc)
  end

  describe '#image' do
    context 'when image has a height' do
      it 'renders the img tag with the correct attributes' do
        markdown = '![Sample Title](https://example.com/image.jpg?cw_image_height=100)'
        expect(render_markdown(markdown)).to include('<img src="https://example.com/image.jpg?cw_image_height=100" height="100" width="auto" />')
      end
    end

    context 'when image does not have a height' do
      it 'renders the img tag without the height attribute' do
        markdown = '![Sample Title](https://example.com/image.jpg)'
        expect(render_markdown(markdown)).to include('<img src="https://example.com/image.jpg" />')
      end
    end

    context 'when image has an invalid URL' do
      it 'renders the img tag without crashing' do
        markdown = '![Sample Title](invalid_url)'
        expect { render_markdown(markdown) }.not_to raise_error
      end
    end
  end
end
