class HtmlParser
  def self.parse_reply(raw_body)
    new(raw_body).filtered_text
  end

  attr_reader :raw_body

  def initialize(raw_body)
    @raw_body = raw_body
  end

  def document
    @document ||= Nokogiri::HTML(raw_body)
  end

  def filter_replies!
    document.xpath('//blockquote').each { |n| n.replace('&gt; ') }
    document.xpath('//table').each(&:remove)
  end

  def filtered_html
    @filtered_html ||= begin
      filter_replies!
      document.inner_html
    end
  end

  def filtered_text
    @filtered_text ||= Html2Text.convert(filtered_html)
  end
end
