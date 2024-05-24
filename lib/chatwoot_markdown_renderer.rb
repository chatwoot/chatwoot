class ChatwootMarkdownRenderer
  def initialize(content)
    @content = content
  end

  def render_message
    markdown_renderer = BaseMarkdownRenderer.new
    doc = CommonMarker.render_doc(@content, :DEFAULT)
    html = markdown_renderer.render(doc)
    render_as_html_safe(html)
  end

  def render_article
    markdown_renderer = CustomMarkdownRenderer.new
    doc = CommonMarker.render_doc(@content, :DEFAULT, [:table])
    html = markdown_renderer.render(doc)

    render_as_html_safe(html)
  end

  def render_markdown_to_plain_text
    CommonMarker.render_doc(@content, :DEFAULT).to_plaintext
  end

  private

  def render_as_html_safe(html)
    # rubocop:disable Rails/OutputSafety
    html.html_safe
    # rubocop:enable Rails/OutputSafety
  end
end
