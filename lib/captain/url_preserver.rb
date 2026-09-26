module Captain::UrlPreserver
  URL_PATTERN = %r{https?://[^\s<>\])]+}
  URL_PLACEHOLDER_PATTERN = /__CHATWOOT_URL_\d+__/

  private

  def protect_urls_in_messages(messages)
    urls = messages.flat_map { |message| message[:content].to_s.scan(URL_PATTERN) }.uniq
    return [messages, {}] if urls.empty?

    placeholders = urls.each_with_index.to_h { |url, index| [url, "__CHATWOOT_URL_#{index}__"] }
    protected_messages = messages.map do |message|
      protected_content = message[:content].to_s.gsub(URL_PATTERN) { |url| placeholders.fetch(url) }
      protected_content += "\n\nKeep every __CHATWOOT_URL_n__ placeholder unchanged." if message[:role] == 'system'
      message.merge(content: protected_content)
    end

    [protected_messages, placeholders]
  end

  def restore_url_placeholders(content, placeholders)
    urls_by_placeholder = placeholders.invert
    content.to_s.gsub(URL_PLACEHOLDER_PATTERN) { |placeholder| urls_by_placeholder.fetch(placeholder, placeholder) }
  end

  def safe_url_placeholder_output?(content, placeholders)
    content.to_s.scan(URL_PATTERN).empty? &&
      (content.to_s.scan(URL_PLACEHOLDER_PATTERN) - placeholders.values).empty?
  end
end
