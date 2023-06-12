class MarkdownRenderer < CommonMarker::HtmlRenderer
  YOUTUBE_REGEX = %r{https?://(?:www\.)?(?:youtube\.com/watch\?v=|youtu\.be/)([^&/]+)}
  VIMEO_REGEX = %r{https?://(?:www\.)?vimeo\.com/(\d+)}
  MP4_REGEX = %r{https?://(?:www\.)?.+\.(mp4)}

  def text(node)
    content = node.string_content

    # Check for presence of '^' in the content
    if content.include?('^')
      # Split the text and insert <sup> tags where necessary
      split_content = parse_sup(content)
      # Output the transformed content
      out(split_content.join)
    else
      # Output the original content
      out(escape_html(content))
    end
  end

  def link(node)
    link_url = node.url

    youtube_match = link_url.match(YOUTUBE_REGEX)
    if youtube_match
      video_id = youtube_match[1]
      embed_code = %(
        <iframe width="560" height="315" src="https://www.youtube.com/embed/#{video_id}" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
      )
      out(embed_code)
      return
    end

    vimeo_match = link_url.match(VIMEO_REGEX)
    if vimeo_match
      video_id = vimeo_match[1]
      embed_code = %(
        <iframe src="https://player.vimeo.com/video/#{video_id}" width="640" height="360" frameborder="0" allow="autoplay; fullscreen; picture-in-picture" allowfullscreen></iframe>
      )
      out(embed_code)
      return
    end

    mp4_match = link_url.match(MP4_REGEX)
    if mp4_match
      embed_code = %(
        <video width="640" height="360" controls>
          <source src="#{link_url}" type="video/mp4">
          Your browser does not support the video tag.
        </video>
      )
      out(embed_code)
      return
    end

    # If it's not YouTube or Vimeo link, render normally
    super
  end

  private

  def parse_sup(content)
    content.split(/(\^[^\^]+\^)/).map do |segment|
      if segment.start_with?('^') && segment.end_with?('^')
        "<sup>#{escape_html(segment[1..-2])}</sup>"
      else
        escape_html(segment)
      end
    end
  end
end
