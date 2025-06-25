require 'rails_helper'

describe CustomMarkdownRenderer do
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

  describe 'broken ^ usage' do
    it 'does not convert text that only starts with ^' do
      markdown = 'This is an example with ^broken superscript.'
      expected_output = '<p>This is an example with ^broken superscript.</p>'
      expect(render_markdown(markdown)).to include(expected_output)
    end

    it 'does not convert text that only ends with ^' do
      markdown = 'This is an example with broken^ superscript.'
      expected_output = '<p>This is an example with broken^ superscript.</p>'
      expect(render_markdown(markdown)).to include(expected_output)
    end

    it 'does not convert text with uneven numbers of ^' do
      markdown = 'This is an example with ^broken^ superscript^.'
      expected_output = '<p>This is an example with <sup>broken</sup> superscript^.</p>'
      expect(render_markdown(markdown)).to include(expected_output)
    end
  end

  describe '#link' do
    def render_markdown_link(link)
      doc = CommonMarker.render_doc("[link](#{link})", :DEFAULT)
      renderer.render(doc)
    end

    context 'when link is a YouTube URL' do
      let(:youtube_url) { 'https://www.youtube.com/watch?v=VIDEO_ID' }

      it 'renders an iframe with YouTube embed code' do
        output = render_markdown_link(youtube_url)
        expect(output).to include('src="https://www.youtube-nocookie.com/embed/VIDEO_ID"')
        expect(output).to include('allowfullscreen')
      end
    end

    context 'when link is a Loom URL' do
      let(:loom_url) { 'https://www.loom.com/share/VIDEO_ID' }

      it 'renders an iframe with Loom embed code' do
        output = render_markdown_link(loom_url)
        expect(output).to include('src="https://www.loom.com/embed/VIDEO_ID"')
        expect(output).to include('webkitallowfullscreen mozallowfullscreen allowfullscreen')
      end
    end

    context 'when link is a Vimeo URL' do
      let(:vimeo_url) { 'https://vimeo.com/1234567' }

      it 'renders an iframe with Vimeo embed code' do
        output = render_markdown_link(vimeo_url)
        expect(output).to include('src="https://player.vimeo.com/video/1234567?dnt=true"')
        expect(output).to include('allowfullscreen')
      end
    end

    context 'when link is an MP4 URL' do
      let(:mp4_url) { 'https://example.com/video.mp4' }

      it 'renders a video element with the MP4 source' do
        output = render_markdown_link(mp4_url)
        expect(output).to include('<video width="640" height="360" controls')
        expect(output).to include('<source src="https://example.com/video.mp4" type="video/mp4">')
      end
    end

    context 'when link is a normal URL' do
      let(:normal_url) { 'https://example.com' }

      it 'renders a normal link' do
        output = render_markdown_link(normal_url)
        expect(output).to include('<a href="https://example.com">')
      end
    end

    context 'when multiple links are present' do
      it 'renders all links when present between empty lines' do
        markdown = "\n[youtube](https://www.youtube.com/watch?v=VIDEO_ID)\n\n[vimeo](https://vimeo.com/1234567)\n^ hello ^ [normal](https://example.com)"
        output = render_markdown(markdown)
        expect(output).to include('src="https://www.youtube-nocookie.com/embed/VIDEO_ID"')
        expect(output).to include('src="https://player.vimeo.com/video/1234567?dnt=true"')
        expect(output).to include('<a href="https://example.com">')
        expect(output).to include('<sup> hello </sup>')
      end
    end

    context 'when links within text are present' do
      it 'renders only text within blank lines as embeds' do
        markdown = "\n[youtube](https://www.youtube.com/watch?v=VIDEO_ID)\nthis is such an amazing [vimeo](https://vimeo.com/1234567)\n[vimeo](https://vimeo.com/1234567)\n"
        output = render_markdown(markdown)
        expect(output).to include('src="https://www.youtube-nocookie.com/embed/VIDEO_ID"')
        expect(output).to include('src="https://player.vimeo.com/video/1234567?dnt=true"')
        expect(output).to include('href="https://vimeo.com/1234567"')
      end
    end

    context 'when link is an Arcade URL' do
      let(:arcade_url) { 'https://app.arcade.software/share/ARCADE_ID' }

      it 'renders an iframe with Arcade embed code' do
        output = render_markdown_link(arcade_url)
        expect(output).to include('src="https://app.arcade.software/embed/ARCADE_ID"')
        expect(output).to include('<iframe')
        expect(output).to include('webkitallowfullscreen')
        expect(output).to include('mozallowfullscreen')
        expect(output).to include('allowfullscreen')
      end

      it 'wraps iframe in responsive container' do
        output = render_markdown_link(arcade_url)
        expect(output).to include('position: relative; padding-bottom: 62.5%; height: 0;')
        expect(output).to include('position: absolute; top: 0; left: 0; width: 100%; height: 100%;')
      end
    end

    context 'when multiple links including Arcade are present' do
      it 'renders Arcade embed along with other content types' do
        markdown = "\n[arcade](https://app.arcade.software/share/ARCADE_ID)\n\n[youtube](https://www.youtube.com/watch?v=VIDEO_ID)\n"
        output = render_markdown(markdown)
        expect(output).to include('src="https://app.arcade.software/embed/ARCADE_ID"')
        expect(output).to include('src="https://www.youtube-nocookie.com/embed/VIDEO_ID"')
      end
    end
  end
end
