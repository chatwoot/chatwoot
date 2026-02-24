class BaseMarkdownRenderer < CommonMarker::HtmlRenderer
  def image(node)
    src, title = extract_img_attributes(node)
    height = extract_image_height(src)

    render_img_tag(src, title, height)
  end

  private

  def extract_img_attributes(node)
    [
      escape_href(node.url),
      escape_html(node.title)
    ]
  end

  def extract_image_height(src)
    query_params = parse_query_params(src)
    query_params['cw_image_height']&.first
  end

  def parse_query_params(url)
    parsed_url = URI.parse(url)
    CGI.parse(parsed_url.query || '')
  rescue URI::InvalidURIError
    {}
  end

  def render_img_tag(src, title, height = nil)
    title_attribute = title.present? ? " title=\"#{title}\"" : ''
    height_attribute = height ? " height=\"#{height}\" width=\"auto\"" : ''

    plain do
      # plain ensures that the content is not wrapped in a paragraph tag
      out("<img src=\"#{src}\"#{title_attribute}#{height_attribute} />")
    end
  end
end
