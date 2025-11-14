class Messages::MarkdownRendererService
  CHANNEL_RENDERERS = {
    'Channel::Email' => :render_html,
    'Channel::WebWidget' => :render_html,
    'Channel::Telegram' => :render_telegram_html,
    'Channel::Whatsapp' => :render_whatsapp,
    'Channel::FacebookPage' => :render_instagram,
    'Channel::Instagram' => :render_instagram,
    'Channel::Line' => :render_line,
    'Channel::Api' => :render_plain_text,
    'Channel::TwitterProfile' => :render_plain_text,
    'Channel::Sms' => :render_plain_text,
    'Channel::TwilioSms' => :render_plain_text
  }.freeze

  def initialize(content, channel_type)
    @content = content
    @channel_type = channel_type
  end

  def render
    return @content if @content.blank?

    renderer_method = CHANNEL_RENDERERS[@channel_type]
    renderer_method ? send(renderer_method) : @content
  end

  private

  def commonmarker_doc
    @commonmarker_doc ||= CommonMarker.render_doc(@content, [:DEFAULT, :STRIKETHROUGH_DOUBLE_TILDE])
  end

  def render_html
    markdown_renderer = BaseMarkdownRenderer.new
    doc = CommonMarker.render_doc(@content, :DEFAULT)
    markdown_renderer.render(doc)
  end

  def render_telegram_html
    text = CGI.escapeHTML(@content.gsub("\n", '<br>'))
    html = CommonMarker.render_html(text).strip
    stripped_html = Rails::HTML5::SafeListSanitizer.new.sanitize(
      html,
      tags: %w[b strong i em u ins s strike del a code pre blockquote],
      attributes: %w[href]
    )
    stripped_html.gsub('&lt;br&gt;', "\n")
  end

  def render_whatsapp
    renderer = WhatsAppRenderer.new
    renderer.render(commonmarker_doc)
  end

  def render_instagram
    renderer = InstagramRenderer.new
    renderer.render(commonmarker_doc)
  end

  def render_line
    renderer = LineRenderer.new
    renderer.render(commonmarker_doc)
  end

  def render_plain_text
    commonmarker_doc.to_plaintext
  end

  class WhatsAppRenderer < CommonMarker::Renderer
    def document(_node)
      out(:children)
    end

    def paragraph(_node)
      out(:children)
      cr
    end

    def strong(_node)
      out('*', :children, '*')
    end

    def emph(_node)
      out('_', :children, '_')
    end

    def code(node)
      out('`', node.string_content, '`')
    end

    def link(node)
      out(node.url)
    end

    def text(node)
      out(node.string_content)
    end

    def softbreak(_node)
      out(' ')
    end

    def linebreak(_node)
      out("\n")
    end

    def list(_node)
      out(:children)
      cr
    end

    def list_item(_node)
      out('- ', :children)
      cr
    end

    def blockquote(_node)
      out('> ', :children)
      cr
    end
  end

  class InstagramRenderer < CommonMarker::Renderer
    def document(_node)
      out(:children)
    end

    def paragraph(_node)
      out(:children)
      cr
    end

    def strong(_node)
      out('*', :children, '*')
    end

    def emph(_node)
      out('_', :children, '_')
    end

    def code(node)
      out(node.string_content)
    end

    def link(node)
      out(node.url)
    end

    def text(node)
      out(node.string_content)
    end

    def softbreak(_node)
      out(' ')
    end

    def linebreak(_node)
      out("\n")
    end

    def list(_node)
      out(:children)
      cr
    end

    def list_item(_node)
      out(:children)
      cr
    end
  end

  class LineRenderer < CommonMarker::Renderer
    def document(_node)
      out(:children)
    end

    def paragraph(_node)
      out(:children)
      cr
    end

    def strong(_node)
      out(' *', :children, '* ')
    end

    def emph(_node)
      out(' _', :children, '_ ')
    end

    def code(node)
      out(' `', node.string_content, '` ')
    end

    def link(node)
      out(node.url)
    end

    def text(node)
      out(node.string_content)
    end

    def softbreak(_node)
      out(' ')
    end

    def linebreak(_node)
      out("\n")
    end

    def list(_node)
      out(:children)
      cr
    end

    def list_item(_node)
      out(:children)
      cr
    end

    def code_block(node)
      out(' ```', "\n", node.string_content, '``` ', "\n")
    end
  end
end
