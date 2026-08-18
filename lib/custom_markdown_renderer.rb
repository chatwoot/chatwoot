class CustomMarkdownRenderer < CommonMarker::HtmlRenderer
  CONFIG_PATH = Rails.root.join('config/markdown_embeds.yml')

  def self.config
    @config ||= YAML.load_file(CONFIG_PATH)
  end

  def self.embeds_config
    @embeds_config ||= config.fetch('embeds')
  end

  def self.embed_regexes
    @embed_regexes ||= embeds_config.each_with_object({}) do |(key, embed_config), acc|
      next unless embed_config.is_a?(Hash) && embed_config['regex']

      acc[key] = Regexp.new(embed_config['regex'])
    end
  end

  def self.trusted_iframe_hosts
    @trusted_iframe_hosts ||= config.fetch('trusted_iframe_hosts').to_set(&:downcase).freeze
  end

  # Matches columnResizing({ cellMinWidth: 50 }) in @chatwoot/prosemirror-schema
  # so cells without an explicit colwidth render the same minimum here as in the editor.
  TABLE_CELL_MIN_WIDTH_PX = 50
  COLWIDTHS_COMMENT = /<!--cw-colwidths:([\d,]+)-->/

  # The article editor serializes column widths as a `<!--cw-colwidths:...-->` HTML
  # comment immediately before each resized table. Capture it (emitting nothing) so the
  # next `table` can size itself; any other raw HTML keeps its default rendering.
  # `html`/`inline_html` are where CommonMarker delivers raw HTML nodes. Without passing the
  # `:UNSAFE` render option, its own default behavior would blank ALL raw HTML out to
  # `<!-- raw HTML omitted -->` here — including the `<img>`/`<iframe>` embeds from
  # https://github.com/chatwoot/chatwoot/issues/14602. We deliberately do NOT enable `:UNSAFE`
  # anywhere in this renderer; instead both node types are routed through
  # EmbeddedHtmlSanitizer's narrow allow-list, which re-renders only `img`/`iframe` and drops
  # everything else exactly as before.
  def html(node)
    match = node.string_content.match(COLWIDTHS_COMMENT)
    if match
      @pending_colwidths = match[1].split(',').map(&:to_i)
      return
    end

    safe_html = embed_sanitizer.sanitize(node.string_content)
    return if safe_html.blank?

    block { out(safe_html) }
  end

  # Raw inline HTML (e.g. a bare `<img ...>` or `<iframe ...>` tag written directly in the
  # article body rather than as a markdown image/link) reaches this node type instead of `html`
  # above.
  def inline_html(node)
    safe_html = embed_sanitizer.sanitize(node.string_content)
    out(safe_html) if safe_html.present?
  end

  def table(node)
    widths = @pending_colwidths
    @pending_colwidths = nil

    if sized_widths?(widths)
      out(table_wrapper_open(widths))
      out(inject_table_sizing(capture_html { super(node) }, widths))
    else
      out('<div class="tableWrapper">')
      super
    end
    out('</div>')
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

  def image(node)
    src = escape_href(node.url)
    width = extract_image_width(src)
    plain do
      out(%(<img src="#{src}"))
      out(' alt="', :children, '"')
      out(%( title="#{escape_html(node.title)}")) if node.title.present?
      out(%( style="width: #{width}; max-width: 100%; height: auto;")) if width
      out(' />')
    end
  end

  private

  def embed_sanitizer
    @embed_sanitizer ||= EmbeddedHtmlSanitizer.new(self.class.trusted_iframe_hosts)
  end

  def sized_widths?(widths)
    widths.is_a?(Array) && widths.any? { |w| w.to_i.positive? }
  end

  def fully_sized?(widths)
    widths.all? { |w| w.to_i.positive? }
  end

  # Fully-sized tables hug their exact width so the card doesn't trail empty space;
  # partial tables stay a plain full-width card so flexible columns can expand.
  def table_wrapper_open(widths)
    return '<div class="tableWrapper">' unless fully_sized?(widths)

    %(<div class="tableWrapper" style="width: #{total_width(widths)}px; max-width: 100%;">)
  end

  # Let the gem render the whole table, then splice a <colgroup> and sizing style
  # into the opening <table> tag. Delegating the row/cell/tbody/alignment markup to
  # super keeps this working across commonmarker upgrades.
  # `!important` overrides the portal's `[&_table]:!min-w-full` Tailwind rule.
  def inject_table_sizing(html, widths)
    opening = %(<table style="#{table_sizing_style(widths)}">\n#{colgroup_html(widths)})
    html.sub(/<table[^>]*>\n?/, opening)
  end

  # Capture everything `super` writes by swapping the renderer's output buffer.
  def capture_html
    original = @stream
    @stream = StringIO.new(+'')
    yield
    @stream.string
  ensure
    @stream = original
  end

  # Total table width: each column's saved width, or the cell min for unsized ones.
  def total_width(widths)
    widths.sum { |w| w.to_i.positive? ? w.to_i : TABLE_CELL_MIN_WIDTH_PX }
  end

  # Fully sized → lock to the exact total (min-width too, so a narrow saved width
  # beats the portal's `[&_table]:!min-w-full`). Partial → `max(100%, total)` fills
  # the container (flexible columns) yet scrolls when the sized columns exceed it.
  def table_sizing_style(widths)
    total = total_width(widths)
    return "table-layout: fixed; min-width: max(100%, #{total}px) !important;" unless fully_sized?(widths)

    "table-layout: fixed; width: #{total}px !important; min-width: #{total}px !important;"
  end

  def colgroup_html(widths)
    cols = widths.map { |w| w.to_i.positive? ? %(<col style="width: #{w.to_i}px;">) : '<col>' }
    "<colgroup>#{cols.join}</colgroup>\n"
  end

  def extract_image_width(src)
    query = URI.parse(src).query
    raw = query && CGI.parse(query)['cw_image_width']&.first
    return unless raw =~ /\A(\d+)px\z/

    px = Regexp.last_match(1).to_i
    "#{px}px" if px.between?(1, 2000)
  rescue URI::InvalidURIError
    nil
  end

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
    embed_config = self.class.embeds_config[embed_key]
    return nil unless embed_config

    template = embed_config['template']
    # Use gsub (not format) so CSS `%` values in templates don't need escaping.
    # Captured values are HTML-escaped since they land inside HTML attribute contexts.
    match_data.named_captures.each do |var_name, value|
      template = template.gsub("%{#{var_name}}", CGI.escapeHTML(value))
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
