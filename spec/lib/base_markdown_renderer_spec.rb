require 'rails_helper'

describe BaseMarkdownRenderer do
  let(:renderer) { described_class.new }

  def render_markdown(markdown)
    doc = CommonMarker.render_doc(markdown, :DEFAULT)
    renderer.render(doc)
  end

  describe '#link' do
    it 'blanks unsafe URLs' do
      unsafe_urls = ['javascript:alert(1)', 'vbscript:alert(1)', 'file:///etc/passwd', 'data:text/html;base64,PHNjcmlwdD4=']

      unsafe_urls.each do |url|
        rendered = render_markdown("[link](#{url})")

        expect(rendered).to include('<a href="">link</a>')
        expect(rendered).not_to include(url)
      end
    end

    it 'preserves custom application protocols' do
      markdown = '[@agent](mention://user/1/Agent)'

      expect(render_markdown(markdown)).to include('href="mention://user/1/Agent"')
    end
  end

  describe '#image' do
    context 'when image has a height' do
      it 'renders the img tag with the correct attributes' do
        markdown = '![Sample Title](https://example.com/image.jpg?cw_image_height=100px)'
        expect(render_markdown(markdown)).to include('<img src="https://example.com/image.jpg?cw_image_height=100px" style="height: 100px;" />')
      end
    end

    context 'when image has a width' do
      it 'renders the img tag with the correct attributes' do
        markdown = '![Sample Title](https://example.com/image.jpg?cw_image_width=200px)'
        expect(render_markdown(markdown)).to include(
          '<img src="https://example.com/image.jpg?cw_image_width=200px" style="width: 200px; max-width: 100%; height: auto;" />'
        )
      end
    end

    context 'when the sizing param contains an attribute-injection payload' do
      it 'drops the malicious height value' do
        markdown = '![x](https://example.com/image.jpg?cw_image_height=1px%22%20onmouseover%3D%22alert(1))'
        rendered = render_markdown(markdown)
        expect(rendered).not_to include('style=')
        expect(rendered).not_to include('onmouseover="')
      end

      it 'drops the malicious width value' do
        markdown = '![x](https://example.com/image.jpg?cw_image_width=1px%22%20onmouseover%3D%22alert(1))'
        rendered = render_markdown(markdown)
        expect(rendered).not_to include('style=')
        expect(rendered).not_to include('onmouseover="')
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

    context 'when image uses an unsafe URL' do
      it 'blanks the source' do
        rendered = render_markdown('![Sample](data:image/svg+xml;base64,PHN2Zz4=)')

        expect(rendered).to include('<img src=""')
        expect(rendered).not_to include('data:image/svg+xml')
      end

      it 'preserves safe image data URLs' do
        rendered = render_markdown('![Sample](data:image/png;base64,AAAA)')

        expect(rendered).to include('src="data:image/png;base64,AAAA"')
      end
    end
  end
end
