class ChatwootMarkdownRenderer
  def initialize(content)
    @content = content
  end

  def render_message
    markdown_renderer = BaseMarkdownRenderer.new
    doc = CommonMarker.render_doc(@content, :DEFAULT, [:strikethrough, :autolink])
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
    allowed_tags = %w[
      a b blockquote br caption code del dd dfn div dl dt em
      h1 h2 h3 h4 h5 h6 i img kbd li mark ol p pre q s samp
      small span strike strong sub sup table tbody td tfoot th thead tr u ul
    ]
    sanitized_html = Rails::HTML5::SafeListSanitizer.new.sanitize(
      html,
      tags: allowed_tags,
      attributes: %w[href title src alt width height rel target]
    )
    sanitized_html.html_safe
  end
end
