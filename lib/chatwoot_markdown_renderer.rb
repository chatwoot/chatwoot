class ChatwootMarkdownRenderer
  def initialize(content)
    @content = content
  end

  def render_message
    markdown_renderer = BaseMarkdownRenderer.new
    content = preserve_multiple_newlines(@content)
    doc = CommonMarker.render_doc(content, :DEFAULT, [:strikethrough])
    html = markdown_renderer.render(doc)
    html = restore_multiple_newlines_as_html(html)
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

  def preserve_multiple_newlines(content)
    content.gsub(/\n{3,}/) do |match|
      extra_blank_lines = match.length - 2
      "\n\n#{'{{BLANK_LINE}}\n\n' * extra_blank_lines}"
    end
  end

  def restore_multiple_newlines_as_html(html)
    html.gsub('<p>{{BLANK_LINE}}</p>', '<p><br></p>')
  end

  def render_as_html_safe(html)
    # rubocop:disable Rails/OutputSafety
    html.html_safe
    # rubocop:enable Rails/OutputSafety
  end
end
