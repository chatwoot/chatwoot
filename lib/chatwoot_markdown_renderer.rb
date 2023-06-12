class ChatwootMarkdownRenderer
  def initialize(markdown_renderer = MarkdownRenderer.new)
    @markdown_renderer = markdown_renderer
  end

  def render_article(content)
    # rubocop:disable Rails/OutputSafety
    doc = CommonMarker.render_doc(content, :DEFAULT)
    html = @markdown_renderer.render(doc)

    html.html_safe
    # rubocop:enable Rails/OutputSafety
  end
end
