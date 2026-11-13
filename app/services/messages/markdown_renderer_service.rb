class Messages::MarkdownRendererService
  CHANNEL_RENDERERS = {
    'Channel::Email' => :render_html,
    'Channel::WebWidget' => :render_html,
    'Channel::Telegram' => :render_telegram_html,
    'Channel::Whatsapp' => :render_whatsapp,
    'Channel::FacebookPage' => :render_instagram,
    'Channel::Instagram' => :render_instagram,
    'Channel::Line' => :render_line,
    'Channel::TwitterProfile' => :render_plain_text,
    'Channel::Sms' => :render_plain_text,
    'Channel::TwilioSms' => :render_plain_text
  }.freeze

  # Lines that start a list item, heading or blockquote, and ATX heading lines
  BLOCK_START = /\A {0,3}(?:(?:[-+*]|\d{1,9}[.)]|\#{1,6})(?:[ \t]|\z)|>)/
  HEADING = /\A {0,3}\#{1,6}(?:[ \t]|\z)/

  def initialize(content, channel_type, channel = nil)
    @content = content
    @channel_type = channel_type
    @channel = channel
  end

  def render
    return @content if @content.blank?

    renderer_method = CHANNEL_RENDERERS[effective_channel_type]
    renderer_method ? send(renderer_method) : @content
  end

  private

  def effective_channel_type
    # For Twilio SMS channel, check if it's actually WhatsApp
    if @channel_type == 'Channel::TwilioSms' && @channel&.whatsapp?
      'Channel::Whatsapp'
    else
      @channel_type
    end
  end

  def commonmarker_doc
    @commonmarker_doc ||= CommonMarker.render_doc(@content, [:DEFAULT, :STRIKETHROUGH_DOUBLE_TILDE])
  end

  def render_html
    markdown_renderer = BaseMarkdownRenderer.new
    doc = CommonMarker.render_doc(@content, :DEFAULT, [:strikethrough, :table])
    markdown_renderer.render(doc)
  end

  def render_telegram_html
    # Strip whitespace from whitespace-only lines to normalize newlines
    normalized_content = @content.gsub(/^[ \t]+$/m, '')
    content_with_preserved_newlines = preserve_multiple_newlines(normalized_content)
    renderer = Messages::MarkdownRenderers::TelegramRenderer.new
    doc = CommonMarker.render_doc(content_with_preserved_newlines, [:STRIKETHROUGH_DOUBLE_TILDE], [:strikethrough])
    result = renderer.render(doc).gsub(/\n+\z/, '')
    restore_multiple_newlines(result)
  end

  def render_whatsapp
    # Strip whitespace from whitespace-only lines to normalize newlines
    normalized_content = @content.gsub(/^[ \t]+$/m, '')
    content_with_preserved_newlines = preserve_multiple_newlines(normalized_content)
    renderer = Messages::MarkdownRenderers::WhatsAppRenderer.new
    doc = CommonMarker.render_doc(content_with_preserved_newlines, [:DEFAULT, :STRIKETHROUGH_DOUBLE_TILDE])
    result = renderer.render(doc).gsub(/\n+\z/, '')
    restore_multiple_newlines(result)
  end

  def render_instagram
    # Strip whitespace from whitespace-only lines to normalize newlines
    normalized_content = @content.gsub(/^[ \t]+$/m, '')
    content_with_preserved_newlines = preserve_multiple_newlines(normalized_content)
    renderer = Messages::MarkdownRenderers::InstagramRenderer.new
    doc = CommonMarker.render_doc(content_with_preserved_newlines, [:DEFAULT, :STRIKETHROUGH_DOUBLE_TILDE])
    result = renderer.render(doc).gsub(/\n+\z/, '')
    restore_multiple_newlines(result)
  end

  def render_line
    # Strip whitespace from whitespace-only lines to normalize newlines
    normalized_content = @content.gsub(/^[ \t]+$/m, '')
    content_with_preserved_newlines = preserve_multiple_newlines(normalized_content)
    renderer = Messages::MarkdownRenderers::LineRenderer.new
    doc = CommonMarker.render_doc(content_with_preserved_newlines, [:DEFAULT, :STRIKETHROUGH_DOUBLE_TILDE])
    result = renderer.render(doc).gsub(/\n+\z/, '')
    restore_multiple_newlines(result)
  end

  def render_plain_text
    # Strip whitespace from whitespace-only lines to normalize newlines
    normalized_content = @content.gsub(/^[ \t]+$/m, '')
    content_with_preserved_newlines = preserve_multiple_newlines(normalized_content)
    renderer = Messages::MarkdownRenderers::PlainTextRenderer.new
    doc = CommonMarker.render_doc(content_with_preserved_newlines, [:DEFAULT, :STRIKETHROUGH_DOUBLE_TILDE])
    result = renderer.render(doc).gsub(/\n+\z/, '')
    restore_multiple_newlines(result)
  end

  # Preserve multiple consecutive newlines (2+) by replacing them with placeholders
  # Standard markdown treats 2 newlines as paragraph break which collapses to 1 newline, we preserve 2+
  # When the blank lines separate blocks, the placeholder gets a paragraph of its own so CommonMark still
  # sees the break; otherwise it stays inline so the surrounding text keeps its exact spacing
  def preserve_multiple_newlines(content)
    content.gsub(/\n{2,}/) do |match|
      if separates_blocks?(Regexp.last_match)
        "\n\n{{PRESERVE_#{match.length}_NEWLINES_BETWEEN_BLOCKS}}\n\n"
      else
        "{{PRESERVE_#{match.length}_NEWLINES}}"
      end
    end
  end

  def separates_blocks?(match)
    line_before = match.pre_match[/[^\n]*\z/]
    line_after = match.post_match[/\A[^\n]*/]
    line_before.present? && (BLOCK_START.match?(line_after) || HEADING.match?(line_before))
  end

  # Restore multiple newlines from placeholders, including the line breaks the renderer put around a block placeholder
  def restore_multiple_newlines(content)
    content.gsub(/\n?\{\{PRESERVE_(\d+)_NEWLINES_BETWEEN_BLOCKS\}\}\n?|\{\{PRESERVE_(\d+)_NEWLINES\}\}/) do |_match|
      "\n" * (Regexp.last_match(1) || Regexp.last_match(2)).to_i
    end
  end
end
