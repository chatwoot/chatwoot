class CustomMarkdownRenderer < CommonMarker::HtmlRenderer
  # TODO: let move this regex from here to a config file where we can update this list much more easily
  # the config file will also have the matching embed template as well.
  YOUTUBE_REGEX = %r{https?://(?:www\.)?(?:youtube\.com/watch\?v=|youtu\.be/)([^&/]+)}
  LOOM_REGEX = %r{https?://(?:www\.)?loom\.com/share/([^&/]+)}
  VIMEO_REGEX = %r{https?://(?:www\.)?vimeo\.com/(\d+)}
  MP4_REGEX = %r{https?://(?:www\.)?.+\.(mp4)}
  ARCADE_REGEX = %r{https?://(?:www\.)?app\.arcade\.software/share/([^&/]+)}
  WISTIA_REGEX = %r{https?://(?:www\.)?([^/]+)\.wistia\.com/medias/([^&/]+)}

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
    return if surrounded_by_empty_lines?(node) && render_embedded_content(node)

    # If it's not YouTube or Vimeo link, render normally
    super
  end

  private

  def surrounded_by_empty_lines?(node)
    prev_node_empty?(node.previous) && next_node_empty?(node.next)
  end

  def prev_node_empty?(prev_node)
    prev_node.nil? || node_empty?(prev_node)
  end

  def next_node_empty?(next_node)
    next_node.nil? || node_empty?(next_node)
  end

  def node_empty?(node)
    (node.type == :text && node.string_content.strip.empty?) || (node.type != :text)
  end

  def render_embedded_content(node)
    link_url = node.url
    embedding_methods = {
      YOUTUBE_REGEX => :make_youtube_embed,
      VIMEO_REGEX => :make_vimeo_embed,
      MP4_REGEX => :make_video_embed,
      LOOM_REGEX => :make_loom_embed,
      ARCADE_REGEX => :make_arcade_embed,
      WISTIA_REGEX => :make_wistia_embed
    }

    embedding_methods.each do |regex, method|
      match = link_url.match(regex)
      if match
        out(send(method, match))
        return true
      end
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
    EmbedRenderer.youtube(video_id)
  end

  def make_loom_embed(loom_match)
    video_id = loom_match[1]
    EmbedRenderer.loom(video_id)
  end

  def make_vimeo_embed(vimeo_match)
    video_id = vimeo_match[1]
    EmbedRenderer.vimeo(video_id)
  end

  def make_video_embed(link_url)
    EmbedRenderer.video(link_url)
  end

  def make_wistia_embed(wistia_match)
    video_id = wistia_match[2]
    EmbedRenderer.wistia(video_id)
  end

  def make_arcade_embed(arcade_match)
    video_id = arcade_match[1]
    EmbedRenderer.arcade(video_id)
  end
end
