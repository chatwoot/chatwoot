class ChatwootMarkdownRenderer
  def initialize(content)
    @content = content
  end

  def render_message
    html = CommonMarker.render_html(@content)
    render_as_html_safe(html)
  end

  def remove_empty_headers
    doc = CommonMarker.render_doc(@content, :DEFAULT)

    doc.walk do |node|
      if node.type == :header
        next_node = node.next
        node.delete if next_node.nil? || (next_node.type == :header && next_node.header_level <= node.header_level)
      end
    end

    @content = doc.to_commonmark
  end

  def render_article
    markdown_renderer = CustomMarkdownRenderer.new
    doc = CommonMarker.render_doc(@content, :DEFAULT)
    html = markdown_renderer.render(doc)

    render_as_html_safe(html)
  end

  private

  def render_as_html_safe(html)
    # rubocop:disable Rails/OutputSafety
    html.html_safe
    # rubocop:enable Rails/OutputSafety
  end
end
