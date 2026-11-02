# frozen_string_literal: true

# Widget visitors can POST arbitrary HTML. Chatwoot stores that string and
# sanitizes it later in the browser (markdown-it html:false + DOMPurify).
# Persist-time stripping is defense in depth so a future client sanitizer
# bypass cannot become stored XSS in the agent dashboard.
#
# CommonMark autolinks are valid visitor text. The HTML5 sanitizer would
# treat those as empty tags, so a small allow-list is parked and restored
# around the strip: http(s), ftp(s), mailto, and local@domain.tld.
# Other schemes (javascript:, data:) and markup that merely contains @
# are not parked.
#
# Oversized payloads skip the HTML5 parser so a 150k+ wrapper cannot
# shrink under Message's content limit and cannot spend parser CPU first.
class Widget::IncomingContentSanitizer
  # Keep in lockstep with Message validations on :content.
  MAX_CONTENT_LENGTH = 150_000

  URI_AUTOLINK_REGEX = %r{<(?:https?|ftps?)://[^<>\s]+>}i
  MAILTO_AUTOLINK_REGEX = /<mailto:[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}>/i
  EMAIL_AUTOLINK_REGEX = /<[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}>/
  AUTO_LINK_REGEX = Regexp.union(URI_AUTOLINK_REGEX, MAILTO_AUTOLINK_REGEX, EMAIL_AUTOLINK_REGEX)

  def self.sanitize(content)
    return content if content.blank?
    return content if content.to_s.length > MAX_CONTENT_LENGTH

    token = SecureRandom.hex(8)
    protected = []
    marked = content.to_s.gsub(AUTO_LINK_REGEX) do |match|
      protected << match
      "[[CWAL:#{token}:#{protected.length - 1}]]"
    end

    stripped = Rails::HTML5::FullSanitizer.new.sanitize(marked)
    stripped.gsub(/\[\[CWAL:#{Regexp.escape(token)}:(\d+)\]\]/) do
      protected[Regexp.last_match(1).to_i] || ''
    end
  end
end
