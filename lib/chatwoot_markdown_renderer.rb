class ChatwootMarkdownRenderer
  def initialize(content)
    @content = content
  end

  def render_message(hardbreaks: false)
    markdown_renderer = BaseMarkdownRenderer.new(options: hardbreaks ? [:HARDBREAKS] : :DEFAULT)
    doc = CommonMarker.render_doc(@content, :DEFAULT, [:strikethrough, :autolink, :table])
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
    doc = CommonMarker.render_doc(@content, :DEFAULT, [:table])
    doc.walk.select { |node| node.type == :table }.each do |table|
      text = CommonMarker::Node.new(:text)
      text.string_content = table.walk.select { |node| node.type.in?([:text, :code]) }.map(&:string_content).join(' ')
      paragraph = CommonMarker::Node.new(:paragraph)
      paragraph.append_child(text)
      table.insert_before(paragraph)
      table.delete
    end
    doc.to_plaintext
  end

  private

  def render_as_html_safe(html)
    # rubocop:disable Rails/OutputSafety
    html.html_safe
    # rubocop:enable Rails/OutputSafety
  end
end
