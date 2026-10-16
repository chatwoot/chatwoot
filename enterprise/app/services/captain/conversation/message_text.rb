# The text of a message as the model sees it: one piece, or one piece per text node of an html email so its markup comes back untouched.
class Captain::Conversation::MessageText
  TEXT_NODES = './/text()[not(ancestor::style or ancestor::script or ancestor::title)]'.freeze

  def initialize(message)
    html = message.content_attributes.dig('email', 'html_content', 'full')
    @document = Nokogiri::HTML(HtmlParser.new(html).filtered_html) if html.present?
    @text = message.content_attributes.dig('email', 'text_content', 'quoted').presence || message.content
  end

  def texts
    @texts ||= @document ? nodes.map { |node| node.text.strip } : [@text]
  end

  def original
    with(texts)
  end

  def with(translations)
    return translations.first unless @document

    nodes.zip(translations) { |node, text| node.content = node.text.sub(node.text.strip) { text } }
    @document.to_html
  end

  private

  def nodes
    @nodes ||= @document.xpath(TEXT_NODES).select { |node| node.text.match?(/\p{L}/) }
  end
end
