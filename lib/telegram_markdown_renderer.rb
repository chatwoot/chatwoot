class TelegramMarkdownRenderer < CommonMarker::HtmlRenderer
  def emph(_node)
    out('<em>', :children, '</em>')
  end

  def strong(_node)
    out('<strong>', :children, '</strong>')
  end
end
