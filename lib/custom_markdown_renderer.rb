class CustomMarkdownRenderer < CommonMarker::HtmlRenderer
  YOUTUBE_REGEX = %r{https?://(?:www\.)?(?:youtube\.com/watch\?v=|youtu\.be/)([^&/]+)}
  VIMEO_REGEX = %r{https?://(?:www\.)?vimeo\.com/(\d+)}
  MP4_REGEX = %r{https?://(?:www\.)?.+\.(mp4)}

  def text(node)
    content = node.string_content

    if content.include?('^')
      split_content = parse_sup(content)
      out(split_content.join)
    else
      out(escape_html(content))
    end
  end

  def link(node)
    if surrounded_by_empty_lines?(node) && render_embedded_content(node)
      return
    end

    # If it's not YouTube or Vimeo link, render normally
    super
  end

  private

  def surrounded_by_empty_lines?(node)
    prev_node = node.previous
    next_node = node.next

    prev_node_empty = prev_node.nil? || 
                  (prev_node.type == :text && prev_node.string_content.strip.empty?) ||
                  (prev_node.type != :text)
    next_node_empty = next_node.nil? ||
                      (next_node.type == :text && next_node.string_content.strip.empty?) ||
                      (next_node.type != :text)
    prev_node_empty && next_node_empty
  end

  def render_embedded_content(node)
    link_url = node.url

    youtube_match = link_url.match(YOUTUBE_REGEX)
    if youtube_match
      out(make_youtube_embed(youtube_match))
      return true
    end

    vimeo_match = link_url.match(VIMEO_REGEX)
    if vimeo_match
      out(make_vimeo_embed(vimeo_match))
      return true
    end

    mp4_match = link_url.match(MP4_REGEX)
    if mp4_match
      out(make_video_embed(link_url))
      return true
    end

    false
  end

  def parse_sup(content)
    content.split(/(\^[^\^]+\^)/).map do |segment|
      if segment.start_with?('^') && segment.end_with?('^')
        "<sup>#{escape_html(segment[1..-2])}</sup>"
      else
        escape_html(segment)
      end
    end
  end

  def make_youtube_embed(youtube_match)
    video_id = youtube_match[1]
    %(
      <iframe
        width="560"
        height="315"
        src="https://www.youtube.com/embed/#{video_id}"
        frameborder="0"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
        allowfullscreen
      ></iframe>
    )
  end

  def make_vimeo_embed(vimeo_match)
    video_id = vimeo_match[1]
    %(
      <iframe
        src="https://player.vimeo.com/video/#{video_id}"
        width="640"
        height="360"
        frameborder="0"
        allow="autoplay; fullscreen; picture-in-picture"
        allowfullscreen
      ></iframe>
    )
  end

  def make_video_embed(link_url)
    %(
      <video width="640" height="360" controls>
        <source src="#{link_url}" type="video/mp4">
        Your browser does not support the video tag.
      </video>
    )
  end
end
