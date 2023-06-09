class SuperscriptRenderer < CommonMarker::HtmlRenderer
  def initialize
    super()
  end

  def text(node)
    content = node.string_content

    # Check for presence of '^' in the content
    if content.include?('^')
      # Split the text and insert <sup> tags where necessary
      split_content = content.split(/(\^[^\^]+\^)/).map do |segment|
        if segment.start_with?('^') && segment.end_with?('^')
          "<sup>#{escape_html(segment[1..-2])}</sup>"
        else
          escape_html(segment)
        end
      end
      # Output the transformed content
      out(split_content.join)
    else
      # Output the original content
      out(escape_html(content))
    end
  end
end
