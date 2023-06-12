class ChatwootMarkdownRenderer
  def initialize(superscript_renderer = SuperscriptRenderer.new)
    @superscript_renderer = superscript_renderer
  end

  def render_article(content)
    # rubocop:disable Rails/OutputSafety
    doc = CommonMarker.render_doc(content, :DEFAULT)
    html = @superscript_renderer.render(doc)

    html.html_safe
    # rubocop:enable Rails/OutputSafety
  end
end
