class ChatwootMarkdownRenderer
  def initialize(content)
    @content = content
  end

  def render_message
    html = CommonMarker.render_html(@content)
    render_as_html_safe(html)
  end

  def render_article
    superscript_renderer = SuperscriptRenderer.new
    doc = CommonMarker.render_doc(@content, :DEFAULT)
    html = superscript_renderer.render(doc)

    render_as_html_safe(html)
  end

  private

  def render_as_html_safe(html)
    # rubocop:disable Rails/OutputSafety
    html.html_safe
    # rubocop:enable Rails/OutputSafety
  end
end
