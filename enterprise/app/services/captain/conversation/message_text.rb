# The translatable text of a message: the text nodes of an html email, otherwise the content itself.
class Captain::Conversation::MessageText
  # Quoted replies were translated as messages of their own; hidden preheaders and titles are never seen.
  TEXT_NODES = <<~XPATH.strip.freeze
    .//text()[not(ancestor::style or ancestor::script or ancestor::title or ancestor::blockquote
      or ancestor::*[contains(@class, 'quote') or contains(@class, 'Quote')]
      or (ancestor::* | preceding::*)[@id='divRplyFwdMsg' or @id='appendonsend']
      or ancestor::*[contains(translate(@style, ' ', ''), 'display:none')])]
  XPATH

  def initialize(message)
    @message = message
    html = message.content_attributes.dig('email', 'html_content', 'full')
    @fragment = Nokogiri::HTML5.fragment(html) if html.present?
  end

  def texts
    @texts ||= @fragment ? nodes.map { |node| node.text.strip } : [@message.content]
  end

  def language
    Captain::Llm::LanguageDetectionService.new(account: @message.account, text: texts.join("\n")).language
  end

  def original
    @fragment ? @fragment.to_html : @message.content
  end

  # Gaps and an unchanged result keep the original, so a message already in the target language is never sent again.
  def translated(translations)
    translations = texts.each_with_index.map { |text, index| translations[index].presence || text }
    return original if unchanged?(translations)
    return translations.first unless @fragment

    nodes.zip(translations) { |node, text| node.content = node.text.sub(node.text.strip) { text } }
    @fragment.to_html
  end

  private

  def unchanged?(translations)
    translations.map(&:strip) == texts.map(&:strip)
  end

  def nodes
    @nodes ||= @fragment.xpath(TEXT_NODES).select { |node| node.text.match?(/\p{L}/) }
  end
end
