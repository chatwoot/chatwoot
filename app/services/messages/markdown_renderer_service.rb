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
    doc = CommonMarker.render_doc(@content, :DEFAULT, [:strikethrough])
    markdown_renderer.render(doc)
  end

  def render_telegram_html
    renderer = Messages::MarkdownRenderers::TelegramRenderer.new
    doc = CommonMarker.render_doc(@content, [:STRIKETHROUGH_DOUBLE_TILDE], [:strikethrough])
    renderer.render(doc).gsub(/\n+\z/, '')
  end

  def render_whatsapp
    renderer = Messages::MarkdownRenderers::WhatsAppRenderer.new
    renderer.render(commonmarker_doc).gsub(/\n+\z/, '')
  end

  def render_instagram
    renderer = Messages::MarkdownRenderers::InstagramRenderer.new
    renderer.render(commonmarker_doc).gsub(/\n+\z/, '')
  end

  def render_line
    renderer = Messages::MarkdownRenderers::LineRenderer.new
    renderer.render(commonmarker_doc).gsub(/\n+\z/, '')
  end

  def render_plain_text
    renderer = Messages::MarkdownRenderers::PlainTextRenderer.new
    renderer.render(commonmarker_doc).gsub(/\n+\z/, '')
  end
end
