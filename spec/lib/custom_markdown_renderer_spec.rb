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
        expect(output).to include('position: relative; padding-bottom: calc(62.793% + 41px); height: 0px; width: 100%;')
        expect(output).to include('position: absolute; top: 0; left: 0; width: 100%; height: 100%;')
      end
    end

    context 'when link is an Arcade tab URL' do
      let(:arcade_tab_url) { 'https://app.arcade.software/share/ARCADE_TAB_ID?embed_mobile=tab' }

      it 'renders an iframe with Arcade tab embed code' do
        output = render_markdown_link(arcade_tab_url)
        expect(output).to include('src="https://app.arcade.software/embed/ARCADE_TAB_ID?embed&embed_mobile=tab"')
      end

      it 'supports additional query params after embed_mobile' do
        url = 'https://app.arcade.software/share/ARCADE_TAB_ID?foo=bar&embed_mobile=tab?user_id=1'
        output = render_markdown_link(url)
        expect(output).to include('src="https://app.arcade.software/embed/ARCADE_TAB_ID?embed&embed_mobile=tab"')
      end

      it 'wraps iframe in responsive container' do
        output = render_markdown_link(arcade_tab_url)
        expect(output).to include('position: relative; padding-bottom: calc(62.793% + 41px); height: 0px; width: 100%;')
        expect(output).to include('position: absolute; top: 0; left: 0; width: 100%; height: 100%;')
      end
    end

    context 'when link is a wistia URL' do
      let(:wistia_url) { 'https://chatwoot.wistia.com/medias/kjwjeq6f9i' }

      it 'renders a custom element with Wistia embed code' do
        output = render_markdown_link(wistia_url)
        expect(output).to include('<script src="https://fast.wistia.com/player.js" async></script>')
        expect(output).to include('<wistia-player')
        expect(output).to include('media-id="kjwjeq6f9i"')
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

    context 'when link is a GuideJar embed URL' do
      let(:guidejar_url) { 'https://www.guidejar.com/embed/i2qMQRp26rtRxpZczmaA' }

      it 'renders an iframe with GuideJar embed code' do
        output = render_markdown_link(guidejar_url)
        expect(output).to include('src="https://www.guidejar.com/embed/i2qMQRp26rtRxpZczmaA?type=1&controls=on"')
        expect(output).to include('allowfullscreen')
      end
    end

    context 'when link is a GuideJar guides URL' do
      let(:guidejar_url) { 'https://guidejar.com/guides/d6a6fdc2-4812-4777-897e-ec1b0c64238f' }

      it 'renders an iframe with GuideJar embed code' do
        output = render_markdown_link(guidejar_url)
        expect(output).to include('src="https://www.guidejar.com/embed/d6a6fdc2-4812-4777-897e-ec1b0c64238f?type=1&controls=on"')
        expect(output).to include('allowfullscreen')
      end

      it 'wraps iframe in responsive container' do
        output = render_markdown_link(guidejar_url)
        expect(output).to include('position: relative; padding-bottom: 62.5%; height: 0;')
        expect(output).to include('position: absolute; top: 0; left: 0; width: 100%; height: 100%;')
      end
    end

    context 'when link is a Bunny.net iframe URL' do
      let(:bunny_url) { 'https://iframe.mediadelivery.net/play/431789/1f105841-cad9-46fe-a70e-b7623c60797c' }

      it 'renders an iframe with Bunny embed code' do
        output = render_markdown_link(bunny_url)
        expect(output).to include('src="https://player.mediadelivery.net/embed/431789/1f105841-cad9-46fe-a70e-b7623c60797c?autoplay=false&loop=false&muted=false&preload=true&responsive=true"')
        expect(output).to include('allowfullscreen')
        expect(output).to include('allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;"')
      end

      it 'wraps iframe in responsive container' do
        output = render_markdown_link(bunny_url)
        expect(output).to include('position: relative; padding-top: 56.25%;')
        expect(output).to include('position: absolute; top: 0; height: 100%; width: 100%;')
      end
    end

    context 'when link is a Bunny.net player URL' do
      let(:bunny_url) { 'https://player.mediadelivery.net/play/431789/1f105841-cad9-46fe-a70e-b7623c60797c' }

      it 'renders an iframe with Bunny embed code' do
        output = render_markdown_link(bunny_url)
        expect(output).to include('embed/431789/1f105841-cad9-46fe-a70e-b7623c60797c')
        expect(output).to include('autoplay=false&loop=false&muted=false&preload=true&responsive=true')
        expect(output).to include('allowfullscreen')
        expect(output).to include('allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;"')
      end
    end

    context 'when captured values contain HTML-special characters' do
      # CommonMark angle-bracket link destinations `[text](<URL>)` permit characters
      # like `"` that the embed regex captures would otherwise pass through raw into
      # attribute values. Captures are HTML-escaped before interpolation so the
      # substituted value cannot break out of the surrounding attribute context.
      it 'escapes double quotes in captured YouTube video_id' do
        markdown = "\n[demo](<https://www.youtube.com/watch?v=x\" onload=\"alert(1)>)\n"
        output = render_markdown(markdown)
        expect(output).not_to include('onload="alert(1)"')
        expect(output).to include('&quot;')
      end

      it 'leaves legitimate alphanumeric IDs untouched' do
        output = render_markdown_link('https://www.youtube.com/watch?v=dQw4w9WgXcQ')
        expect(output).to include('src="https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ"')
      end
    end
  end

  describe '#table' do
    def render_table(markdown)
      doc = CommonMarker.render_doc(markdown, :DEFAULT, [:table])
      described_class.new.render(doc)
    end

    let(:plain_table) { "| A | B |\n| --- | --- |\n| 1 | 2 |\n" }

    it 'renders a table without column widths when no marker is present' do
      output = render_table(plain_table)
      expect(output).to include('<div class="tableWrapper"><table>')
      expect(output).not_to include('colgroup')
      expect(output).not_to include('cw-colwidths')
    end

    context 'when every column has a saved width' do
      it 'lays the table out at the total width with a sized colgroup' do
        output = render_table("<!--cw-colwidths:120,200-->\n#{plain_table}")
        # Wrapper hugs the table; min-width is set alongside width so a narrow saved width beats min-w-full.
        expect(output).to include('<div class="tableWrapper" style="width: 320px; max-width: 100%;">')
        expect(output).to include('<table style="table-layout: fixed; width: 320px !important; min-width: 320px !important;">')
        expect(output).to include('<colgroup><col style="width: 120px;"><col style="width: 200px;"></colgroup>')
      end
    end

    context 'when only some columns have a saved width' do
      it 'fills the container so unsized columns stay flexible, floored at the sized total' do
        output = render_table("<!--cw-colwidths:150,0-->\n#{plain_table}")
        # max(100%, 200px): fills the container (flexible) but scrolls if the sized columns exceed it.
        expect(output).to include('table-layout: fixed; min-width: max(100%, 200px) !important;')
        expect(output).to include('<colgroup><col style="width: 150px;"><col></colgroup>')
        # No exact-width lock on the wrapper or table — the table must be free to expand.
        expect(output).to include('<div class="tableWrapper"><table')
        expect(output).not_to include('width: 200px !important')
      end
    end

    it 'associates each marker with the table that follows it' do
      markdown = "#{plain_table}\n<!--cw-colwidths:150,250-->\n| P | Q |\n| --- | --- |\n| a | b |\n"
      output = render_table(markdown)

      # First table has no marker and stays unsized; the marker applies to the second table.
      expect(output).to include('<div class="tableWrapper"><table>')
      expect(output).to include('width: 400px !important;')
      expect(output).to include('<col style="width: 250px;">')
      expect(output.scan('colgroup').length).to eq(2)
    end

    it 'does not emit the marker comment into the rendered html' do
      expect(render_table("<!--cw-colwidths:120,200-->\n#{plain_table}")).not_to include('cw-colwidths')
    end
  end

  describe 'raw HTML embeds (img/iframe allow-list)' do
    # These exercise the `html`/`inline_html` node types, which is what raw HTML submitted via
    # the Portal Articles API parses into (as opposed to markdown image/link syntax, which uses
    # the `image`/`link` node types tested elsewhere in this file).
    def render_html(html)
      doc = CommonMarker.render_doc(html, :DEFAULT)
      renderer.render(doc)
    end

    context 'with the exact payload from the reported issue' do
      it 'renders the trusted YouTube iframe and the image, dropping the surrounding raw markup' do
        html = '<p>This article has a video and an image.</p>' \
               '<div><iframe src="https://www.youtube.com/embed/dQw4w9WgXcQ" frameborder="0" allowfullscreen></iframe></div>' \
               '<p>And here is an image:</p><img src="https://example.com/screenshot.png" width="600">' \
               '<p>End of article.</p>'
        output = render_html(html)

        expect(output).to include('<iframe src="https://www.youtube.com/embed/dQw4w9WgXcQ"')
        expect(output).to include('allowfullscreen')
        expect(output).to include('<img src="https://example.com/screenshot.png" width="600" />')
      end
    end

    context 'with a trusted iframe host' do
      it 'renders a bare Loom iframe' do
        html = '<iframe src="https://www.loom.com/embed/VIDEO_ID" allowfullscreen></iframe>'
        expect(render_html(html)).to include('<iframe src="https://www.loom.com/embed/VIDEO_ID" frameborder="0" allowfullscreen></iframe>')
      end
    end

    context 'with an untrusted iframe host' do
      it 'drops the iframe entirely' do
        html = '<iframe src="https://evil.com/phish"></iframe>'
        output = render_html(html)
        expect(output).not_to include('<iframe')
        expect(output).not_to include('evil.com')
      end
    end

    context 'with a plain http(s) image' do
      it 'renders the image' do
        html = '<img src="https://example.com/pic.png" alt="A pic" title="Nice">'
        output = render_html(html)
        expect(output).to include('<img src="https://example.com/pic.png" alt="A pic" title="Nice" />')
      end
    end

    describe 'XSS regression coverage' do
      it 'strips a raw <script> tag' do
        output = render_html('<script>alert(1)</script>')
        expect(output).not_to include('<script')
        expect(output).not_to include('alert(1)')
      end

      it 'drops an <img> with a relative/non-URL src (classic onerror payload)' do
        output = render_html('<img src=x onerror=alert(1)>')
        expect(output).not_to include('onerror')
        expect(output).not_to include('alert(1)')
        expect(output).not_to include('<img')
      end

      it 'drops an <img> with a javascript: src' do
        output = render_html('<img src="javascript:alert(1)">')
        expect(output).not_to include('javascript:')
        expect(output).not_to include('<img')
      end

      it 'drops an <iframe> with a javascript: src' do
        output = render_html('<iframe src="javascript:alert(1)"></iframe>')
        expect(output).not_to include('javascript:')
        expect(output).not_to include('<iframe')
      end

      it 'drops an <iframe> with a data: src' do
        output = render_html('<iframe src="data:text/html,<script>alert(1)</script>"></iframe>')
        expect(output).not_to include('<iframe')
        expect(output).not_to include('<script')
      end

      it 'drops an <img> with a data: src (no data URIs allowed for images either)' do
        output = render_html('<img src="data:image/png;base64,AAAA">')
        expect(output).not_to include('<img')
        expect(output).not_to include('data:')
      end

      it 'drops an <iframe> with a protocol-relative src' do
        output = render_html('<iframe src="//evil.com/x"></iframe>')
        expect(output).not_to include('<iframe')
        expect(output).not_to include('evil.com')
      end

      it 'drops an <iframe> whose src uses userinfo to disguise the real host' do
        output = render_html('<iframe src="https://www.youtube.com@evil.com/x"></iframe>')
        expect(output).not_to include('<iframe')
        expect(output).not_to include('evil.com')
      end

      it 'does not allow a look-alike host to pass as a trusted host' do
        output = render_html('<iframe src="https://evilyoutube.com/embed/x"></iframe>')
        expect(output).not_to include('<iframe')
      end

      it 'does not allow a trusted-looking suffix host to pass as trusted' do
        output = render_html('<iframe src="https://www.youtube.com.evil.com/embed/x"></iframe>')
        expect(output).not_to include('<iframe')
      end

      it 'strips a raw <a href="javascript:..."> tag entirely (anchor is not on the allow-list)' do
        output = render_html('<a href="javascript:alert(1)">click me</a>')
        expect(output).not_to include('<a ')
        expect(output).not_to include('javascript:')
      end

      it 'ignores an iframe srcdoc attribute even when no usable src is present' do
        output = render_html('<iframe srcdoc="<script>alert(1)</script>"></iframe>')
        expect(output).not_to include('<script')
        expect(output).not_to include('<iframe')
      end

      it 'does not let a malicious width/height value inject extra attributes onto a safe image' do
        html = %(<img src="https://example.com/pic.png" width="1&quot; onerror=&quot;alert(1)">)
        output = render_html(html)
        expect(output).to include('<img src="https://example.com/pic.png" />')
        expect(output).not_to include('onerror')
      end

      it 'is not fooled by uppercase tag/attribute names' do
        output = render_html('<IFRAME SRC="javascript:alert(1)"></IFRAME>')
        expect(output).not_to include('<iframe')
        expect(output.downcase).not_to include('javascript:')
      end

      it 'still omits unrelated raw HTML (e.g. a div wrapper) as a bare comment-free no-op' do
        output = render_html('<div class="foo">hello</div>')
        expect(output).not_to include('<div')
        expect(output).not_to include('class="foo"')
      end
    end
  end

  describe '#image' do
    it 'renders width in px with responsive cap and auto height' do
      markdown = '![Sample](https://example.com/image.jpg?cw_image_width=400px)'
      expect(render_markdown(markdown)).to include(
        'style="width: 400px; max-width: 100%; height: auto;"'
      )
    end

    it 'ignores a non-numeric width' do
      markdown = '![Sample](https://example.com/image.jpg?cw_image_width=auto)'
      expect(render_markdown(markdown)).not_to include('style=')
    end
  end
end
