module MarkdownRendererUrlSanitizer
  # Match CommonMarker's native safe renderer while retaining application protocols such as mention://.
  DANGEROUS_URL_PATTERN = /\A(?:javascript:|vbscript:|file:|data:)/i
  SAFE_DATA_IMAGE_PATTERN = %r{\Adata:image/(?:png|gif|jpeg|webp)}i

  def link(node)
    out('<a href="', sanitized_href(node.url), '"')
    out(' title="', escape_html(node.title), '"') if node.title.present?
    out('>', :children, '</a>')
  end

  private

  def sanitized_href(url)
    url = url.to_s
    return '' if url.match?(DANGEROUS_URL_PATTERN) && !url.match?(SAFE_DATA_IMAGE_PATTERN)

    escape_href(url)
  end
end
