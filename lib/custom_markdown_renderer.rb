class CustomMarkdownRenderer < CommonMarker::HtmlRenderer
  CONFIG_PATH = Rails.root.join('config/markdown_embeds.yml')

  def self.config
    @config ||= YAML.load_file(CONFIG_PATH)
  end

  def self.embed_regexes
    @embed_regexes ||= config.transform_values { |embed_config| Regexp.new(embed_config['regex']) }
  end

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

    # If it's not a supported embed link, render normally
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
    embed_html = find_matching_embed(link_url)

    return false unless embed_html

    out(embed_html)
    true
  end

  def find_matching_embed(link_url)
    self.class.embed_regexes.each do |embed_key, regex|
      match = link_url.match(regex)
      next unless match

      return render_embed_from_match(embed_key, match)
    end

    nil
  end

  def render_embed_from_match(embed_key, match_data)
    embed_config = self.class.config[embed_key]
    return nil unless embed_config

    template = embed_config['template']
    # Use Ruby's built-in named captures with gsub to handle CSS % values
    match_data.named_captures.each do |var_name, value|
      template = template.gsub("%{#{var_name}}", value)
    end
    template
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
end
