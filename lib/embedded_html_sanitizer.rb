# Sanitizes a raw HTML fragment down to a narrow allow-list of `<img>`/`<iframe>` tags.
#
# Used by CustomMarkdownRenderer to support articles created via the Portal Articles API with
# raw HTML `<img>`/`<iframe>` embeds (see https://github.com/chatwoot/chatwoot/issues/14602).
# CommonMarker's default (non-`:UNSAFE`) rendering replaces ALL raw HTML — block or inline —
# with an opaque placeholder comment. This class is deliberately NOT a general raw-HTML
# passthrough: it re-renders only `img`/`iframe` elements that pass strict validation, rebuilt
# attribute-by-attribute from scratch (never copying any raw attribute string from the input).
# Everything else in the fragment — any other tag, any other attribute, any bare text — is
# dropped, matching CommonMarker's existing default behavior for unrecognized raw HTML.
class EmbeddedHtmlSanitizer
  ALLOWED_TAGS = %w[img iframe].freeze
  SAFE_DIMENSION = /\A\d{1,4}\z/

  def initialize(trusted_iframe_hosts)
    @trusted_iframe_hosts = trusted_iframe_hosts
  end

  # Nokogiri only builds a DOM tree here; it never executes anything, so parsing
  # attacker-controlled markup is safe.
  def sanitize(raw_html)
    fragment = Nokogiri::HTML5.fragment(raw_html)
    fragment.css(ALLOWED_TAGS.join(', ')).filter_map { |element| render_safe_embed(element) }.join
  rescue Nokogiri::SyntaxError, ArgumentError
    ''
  end

  private

  def render_safe_embed(element)
    case element.name
    when 'img' then render_safe_img(element)
    when 'iframe' then render_safe_iframe(element)
    end
  end

  def render_safe_img(element)
    src = safe_http_url(element['src'])
    return nil unless src

    tag = %(<img src="#{CGI.escapeHTML(src)}")
    tag << %( alt="#{CGI.escapeHTML(element['alt'])}") if element['alt'].present?
    tag << %( title="#{CGI.escapeHTML(element['title'])}") if element['title'].present?
    tag << %( width="#{element['width']}") if safe_dimension?(element['width'])
    tag << %( height="#{element['height']}") if safe_dimension?(element['height'])
    tag << ' />'
    tag
  end

  def render_safe_iframe(element)
    src = safe_http_url(element['src'])
    return nil unless src && trusted_iframe_host?(src)

    tag = %(<iframe src="#{CGI.escapeHTML(src)}" frameborder="0")
    tag << %( width="#{element['width']}") if safe_dimension?(element['width'])
    tag << %( height="#{element['height']}") if safe_dimension?(element['height'])
    tag << %( title="#{CGI.escapeHTML(element['title'])}") if element['title'].present?
    tag << ' allowfullscreen' if element.key?('allowfullscreen')
    tag << '></iframe>'
    tag
  end

  # Only an absolute http/https URL is accepted — `URI.parse` classifies any other scheme
  # (javascript:, data:, vbscript:, file:, protocol-relative //, etc.) as something other than
  # a `URI::HTTP` instance, and malformed/illegal-character URLs raise and are rejected too.
  # Nokogiri has already HTML-entity-decoded the attribute value by this point, so there is no
  # separate decode step that could be bypassed with double-encoding.
  def safe_http_url(value)
    return nil if value.blank?

    uri = URI.parse(value.strip)
    return nil unless uri.is_a?(URI::HTTP) && uri.host.present?

    uri.to_s
  rescue URI::InvalidURIError
    nil
  end

  # Exact, case-insensitive host match only — no subdomain/suffix matching — so
  # "evilyoutube.com" or "youtube.com.attacker.com" cannot pass as "youtube.com". Also defeats
  # userinfo tricks like "https://youtube.com@evil.com/x" since `URI#host` only ever returns
  # the actual host ("evil.com" there), never the userinfo segment.
  def trusted_iframe_host?(url)
    host = URI.parse(url).host&.downcase
    @trusted_iframe_hosts.include?(host)
  rescue URI::InvalidURIError
    false
  end

  def safe_dimension?(value)
    value.present? && SAFE_DIMENSION.match?(value)
  end
end
