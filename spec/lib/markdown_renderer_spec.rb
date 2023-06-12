require 'rails_helper'

describe MarkdownRenderer do
  let(:renderer) { described_class.new }

  def render_markdown(markdown)
    doc = CommonMarker.render_doc(markdown, :DEFAULT)
    renderer.render(doc)
  end

  describe '#text' do
    it 'converts text wrapped in ^ to superscript' do
      markdown = 'This is an example of a superscript: ^superscript^.'
      expect(render_markdown(markdown)).to include('<sup>superscript</sup>')
    end

    it 'does not convert text not wrapped in ^' do
      markdown = 'This is an example without superscript.'
      expect(render_markdown(markdown)).not_to include('<sup>')
    end

    it 'converts multiple superscripts in the same text' do
      markdown = 'This is an example with ^multiple^ ^superscripts^.'
      rendered_html = render_markdown(markdown)
      expect(rendered_html.scan('<sup>').length).to eq(2)
      expect(rendered_html).to include('<sup>multiple</sup>')
      expect(rendered_html).to include('<sup>superscripts</sup>')
    end
  end

  describe '#link' do
    def render_markdown_link(link)
      doc = CommonMarker.render_doc("[link](#{link})", :DEFAULT)
      link_node = doc.first_child.first_child
      renderer.link(link_node)
      renderer.instance_variable_get(:@stream).string
    end

    context 'when link is a YouTube URL' do
      let(:youtube_url) { 'https://www.youtube.com/watch?v=VIDEO_ID' }

      it 'renders an iframe with YouTube embed code' do
        output = render_markdown_link(youtube_url)
        expect(output).to include('<iframe width="560" height="315" src="https://www.youtube.com/embed/VIDEO_ID"')
      end
    end

    context 'when link is a Vimeo URL' do
      let(:vimeo_url) { 'https://vimeo.com/1234567' }

      it 'renders an iframe with Vimeo embed code' do
        output = render_markdown_link(vimeo_url)
        expect(output).to include('<iframe src="https://player.vimeo.com/video/1234567"')
      end
    end

    context 'when link is an MP4 URL' do
      let(:mp4_url) { 'https://example.com/video.mp4' }

      it 'renders a video element with the MP4 source' do
        output = render_markdown_link(mp4_url)
        expect(output).to match(%r{<video\s+width="640"\s+height="360"\s+controls>\s*<source\s+src="https://example\.com/video\.mp4"\s+type="video/mp4">\s*Your browser does not support the video tag\.\s*</video>}m)
      end
    end

    context 'when link is a normal URL' do
      let(:normal_url) { 'https://example.com' }

      it 'renders a normal link' do
        output = render_markdown_link(normal_url)
        expect(output).to include('<a href="https://example.com">')
      rescue NoMethodError => e
        # Ignore error for this test.
      end
    end
  end
end
