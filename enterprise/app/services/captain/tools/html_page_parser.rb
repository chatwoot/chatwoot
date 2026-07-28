class Captain::Tools::HtmlPageParser
  attr_reader :doc

  def initialize(html)
    @doc = Nokogiri::HTML(html)
  end

  def title
    @doc.at_xpath('//title')&.text&.strip
  end

  def body_markdown
    ReverseMarkdown.convert(@doc.at_xpath('//body'), unknown_tags: :bypass, github_flavored: true)
  end
end
