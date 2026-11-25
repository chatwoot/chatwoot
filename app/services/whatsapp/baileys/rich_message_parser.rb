# Parses Baileys "rich" message proto shapes (template / interactive / buttons /
# list and their response variants) into a normalized hash the dashboard renders
# as a structured card, plus a flat text rendering used for `content`/previews.
#
# The Baileys bridge forwards the raw proto via JSON.stringify (camelCase keys,
# enums as number OR string). We only read string fields here, so the enum
# number-vs-string ambiguity does not affect this parser. The one risky shape is
# interactiveMessage's nativeFlow `buttonParamsJson` (a snake_case JSON string),
# parsed defensively so a malformed/unexpected payload degrades to is_unsupported
# instead of raising. Branches not yet exercised by a real captured payload are
# tagged `# UNVERIFIED`.
class Whatsapp::Baileys::RichMessageParser
  RICH_KEYS = %i[
    interactiveMessage templateMessage buttonsMessage listMessage
    buttonsResponseMessage listResponseMessage templateButtonReplyMessage interactiveResponseMessage
    pollCreationMessage pollCreationMessageV2 pollCreationMessageV3
  ].freeze

  # Tried in order; mirrors Baileys' extractMessageContent. First non-nil wins.
  PARSERS = %i[
    parse_interactive parse_template parse_buttons parse_list
    parse_buttons_response parse_list_response parse_template_reply parse_interactive_response
    parse_poll
  ].freeze

  # Media that can sit in a rich header, mapped to Chatwoot attachment kinds.
  MEDIA_HEADER_KINDS = { imageMessage: 'image', videoMessage: 'video', documentMessage: 'file' }.freeze

  class << self
    def rich?(msg)
      RICH_KEYS.any? { |key| msg.key?(key) }
    end

    # Renders the normalized hash into the plain-text body stored as `content`.
    def to_text(parsed)
      return if parsed.blank?

      lines = [parsed[:title], parsed[:body], parsed[:footer], *button_lines(parsed[:buttons])]
      lines.compact_blank.join("\n\n").presence
    end

    private

    def button_lines(buttons)
      Array(buttons).map do |button|
        suffix = button[:url].presence || button[:phone].presence
        suffix ? "▸ #{button[:text]}: #{suffix}" : "▸ #{button[:text]}"
      end
    end
  end

  def initialize(msg)
    @msg = msg
  end

  # Normalized hash ({ type:, title:, body:, footer:, buttons: [...] }) or nil.
  def parse
    PARSERS.lazy.filter_map { |parser| send(parser) }.first
  end

  # contextInfo of the current rich subtype, where externalAdReply (CTWA) lives.
  def context_info
    @msg.dig(:templateMessage, :contextInfo) ||
      interactive_payload&.dig(:contextInfo) ||
      @msg.dig(:buttonsMessage, :contextInfo) ||
      @msg.dig(:listMessage, :contextInfo) ||
      @msg.dig(:interactiveResponseMessage, :contextInfo)
  end

  # Media nested in a rich header (template/interactive/buttons), e.g. an invoice
  # PDF in a template header. Returns { kind: 'image'|'video'|'file', node: } or nil.
  def media_header
    source = template_header || interactive_payload&.dig(:header) || @msg[:buttonsMessage]
    return if source.blank?

    MEDIA_HEADER_KINDS.each do |key, kind|
      node = source[key]
      return { kind: kind, node: node } if node.present?
    end
    nil
  end

  private

  def template_header
    @msg.dig(:templateMessage, :hydratedFourRowTemplate) || @msg.dig(:templateMessage, :hydratedTemplate)
  end

  # WABA "interactive" templates arrive as an InteractiveMessage nested under
  # templateMessage.interactiveMessageTemplate instead of at the top level.
  def interactive_payload
    @msg[:interactiveMessage] || @msg.dig(:templateMessage, :interactiveMessageTemplate)
  end

  def parse_template
    tpl = template_header
    return if tpl.blank?

    buttons = Array(tpl[:hydratedButtons]).filter_map { |button| template_button(button) }
    build('template', title: tpl[:hydratedTitleText], body: tpl[:hydratedContentText],
                      footer: tpl[:hydratedFooterText], buttons: buttons)
  end

  def template_button(button)
    if (quick = button[:quickReplyButton])
      { text: quick[:displayText] }
    elsif (url = button[:urlButton])
      { text: url[:displayText], url: url[:url] }
    elsif (call = button[:callButton])
      { text: call[:displayText], phone: call[:phoneNumber] }
    end
  end

  def parse_interactive
    interactive = interactive_payload
    return if interactive.blank?

    buttons = Array(interactive.dig(:nativeFlowMessage, :buttons)).flat_map { |button| native_flow_buttons(button) }
    build('interactive', title: interactive.dig(:header, :title), body: interactive.dig(:body, :text),
                         footer: interactive.dig(:footer, :text), buttons: buttons)
  end

  # buttonParamsJson is a snake_case JSON string; parse defensively. Returns an
  # array because single_select expands into one entry per row.
  def native_flow_buttons(button) # rubocop:disable Metrics/CyclomaticComplexity
    params = parse_json(button[:buttonParamsJson])
    case button[:name]
    when 'cta_url' then [{ text: params['display_text'], url: params['url'] }]
    when 'cta_call' then [{ text: params['display_text'], phone: params['phone_number'] }]
    when 'open_webview' then [{ text: params['title'] || params['display_text'], url: params.dig('link', 'url') }]
    when 'single_select' then Array(params['sections']).flat_map { |s| Array(s['rows']) }.map { |r| { text: r['title'] } }
    else [{ text: params['display_text'] || params['title'] || params['flow_cta'] }] # quick_reply, cta_copy, flow, ...
    end
  end

  # UNVERIFIED: no real buttonsMessage payload captured yet.
  def parse_buttons
    buttons_msg = @msg[:buttonsMessage]
    return if buttons_msg.blank?

    buttons = Array(buttons_msg[:buttons]).filter_map do |button|
      text = button.dig(:buttonText, :displayText)
      { text: text } if text.present?
    end
    build('buttons', title: buttons_msg[:text], body: buttons_msg[:contentText],
                     footer: buttons_msg[:footerText], buttons: buttons)
  end

  # UNVERIFIED: no real listMessage payload captured yet.
  def parse_list
    list_msg = @msg[:listMessage]
    return if list_msg.blank?

    rows = Array(list_msg[:sections]).flat_map { |section| Array(section[:rows]) }
                                     .filter_map { |row| { text: row[:title] } if row[:title].present? }
    build('list', title: list_msg[:title], body: list_msg[:description],
                  footer: list_msg[:footerText], buttons: rows)
  end

  # UNVERIFIED: no real *ResponseMessage payload captured yet.
  def parse_buttons_response
    build('buttons_response', body: @msg.dig(:buttonsResponseMessage, :selectedDisplayText))
  end

  def parse_list_response
    build('list_response', body: @msg.dig(:listResponseMessage, :title))
  end

  def parse_template_reply
    build('template_reply', body: @msg.dig(:templateButtonReplyMessage, :selectedDisplayText))
  end

  def parse_interactive_response
    build('interactive_response', body: @msg.dig(:interactiveResponseMessage, :body, :text))
  end

  def parse_poll
    poll = @msg[:pollCreationMessage] || @msg[:pollCreationMessageV2] || @msg[:pollCreationMessageV3]
    return if poll.blank?

    options = Array(poll[:options]).filter_map { |option| { text: option[:optionName] } if option[:optionName].present? }
    build('poll', title: poll[:name], buttons: options)
  end

  # Returns the normalized hash only when there is something renderable, else nil
  # (the caller marks the message as unsupported).
  def build(type, title: nil, body: nil, footer: nil, buttons: [])
    cleaned = buttons.map(&:compact).reject { |button| button[:text].blank? }
    return if title.blank? && body.blank? && footer.blank? && cleaned.empty?

    { type: type, title: title.presence, body: body.presence, footer: footer.presence, buttons: cleaned.presence }.compact
  end

  def parse_json(str)
    return {} if str.blank?

    parsed = JSON.parse(str)
    parsed.is_a?(Hash) ? parsed : {}
  rescue JSON::ParserError, TypeError
    {}
  end
end
