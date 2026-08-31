class BaseMarkdownRenderer < CommonMarker::HtmlRenderer
  def image(node)
    src, title = extract_img_attributes(node)
    sizing_style = extract_image_sizing_style(src)

    render_img_tag(src, title, sizing_style)
  end

  private

  def extract_img_attributes(node)
    [
      escape_href(node.url),
      escape_html(node.title)
    ]
  end

  # Drag-resize from the reply editor encodes the chosen width as cw_image_width
  # on the URL; the older message-signature picker uses cw_image_height. Width
  # wins when both are set so the agent's most recent intent is honored.
  def extract_image_sizing_style(src)
    query_params = parse_query_params(src)
    width = sanitize_pixel_value(query_params['cw_image_width']&.first)
    return "width: #{width}; max-width: 100%; height: auto;" if width

    height = sanitize_pixel_value(query_params['cw_image_height']&.first)
    height ? "height: #{height};" : nil
  end

  # Only allow a bounded `<digits>px` value so the decoded query param can't
  # break out of the inline style attribute (HTML attribute injection).
  def sanitize_pixel_value(raw)
    return unless raw =~ /\A(\d+)px\z/

    px = Regexp.last_match(1).to_i
    "#{px}px" if px.between?(1, 2000)
  end

  def parse_query_params(url)
    parsed_url = URI.parse(url)
    CGI.parse(parsed_url.query || '')
  rescue URI::InvalidURIError
    {}
  end

  def render_img_tag(src, title, sizing_style = nil)
    title_attribute = title.present? ? " title=\"#{title}\"" : ''
    # Use inline style instead of HTML width/height attributes: email clients
    # and the in-app Letter view both run images through CSS (e.g. prose /
    # lettersanitizer's `img { height: auto }`) which overrides presentational
    # attributes. Inline style has higher specificity and survives.
    style_attribute = sizing_style ? " style=\"#{sizing_style}\"" : ''

    plain do
      # plain ensures that the content is not wrapped in a paragraph tag
      out("<img src=\"#{src}\"#{title_attribute}#{style_attribute} />")
    end
  end
end
