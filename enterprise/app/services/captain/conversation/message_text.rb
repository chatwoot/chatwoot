# The text of a message as the model sees it: one piece, or one piece per text node of an html email so its markup comes back untouched.
class Captain::Conversation::MessageText
  TEXT_NODES = './/text()[not(ancestor::style or ancestor::script or ancestor::title)]'.freeze
  QUOTES = '[class*="quote"], [class*="Quote"]'.freeze

  def initialize(message)
    html = message.content_attributes.dig('email', 'html_content', 'full')
    @document = Nokogiri::HTML(html) if html.present?
    # A forward sits entirely inside the quoted history; with no visible text left it is read as plain content.
    @document = nil if @document && nodes.empty?
    @text = message.content
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
    @nodes ||= (@document.xpath(TEXT_NODES).to_a - quoted_nodes).select { |node| node.text.match?(/\p{L}/) }
  end

  # The quoted history the dashboard collapses (emailQuoteExtractor.js): quote containers and a trailing blockquote.
  def quoted_nodes
    quotes = @document.css(QUOTES).to_a
    trailing = @document.at('body')&.element_children&.last
    quotes << trailing if trailing&.name == 'blockquote'
    quotes.flat_map { |quote| quote.xpath('.//text()').to_a }
  end
end
