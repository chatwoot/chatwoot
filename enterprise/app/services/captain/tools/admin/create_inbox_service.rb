class Captain::Tools::Admin::CreateInboxService < Captain::Tools::Admin::BaseTool
  SUPPORTED_CHANNEL_TYPES = %w[api web_widget].freeze

  def self.name
    'create_inbox'
  end

  description 'Create a new inbox with an API or website channel. Requires user confirmation.'
  param :confirmed, type: :boolean, desc: 'Must be true after the user explicitly confirms the change', required: true
  param :name, type: :string, desc: 'Inbox name', required: true
  param :channel_type, type: :string, desc: 'Channel type: api or web_widget', required: true
  param :website_url, type: :string, desc: 'Website URL (required for web_widget)'
  param :webhook_url, type: :string, desc: 'Webhook URL (optional for api channel)'
  param :widget_color, type: :string, desc: 'Widget color for web_widget (e.g. #1f93ff)'

  def execute(confirmed:, name:, channel_type:, website_url: nil, webhook_url: nil, widget_color: nil)
    confirmation_error = require_confirmation!(
      confirmed,
      name: name,
      channel_type: channel_type,
      website_url: website_url,
      webhook_url: webhook_url,
      widget_color: widget_color
    )
    return confirmation_error if confirmation_error.present?

    unless SUPPORTED_CHANNEL_TYPES.include?(channel_type)
      return "Unsupported channel type: #{channel_type}. Supported types: #{SUPPORTED_CHANNEL_TYPES.join(', ')}"
    end

    inbox = nil
    ActiveRecord::Base.transaction do
      channel = create_channel(channel_type, website_url: website_url, webhook_url: webhook_url, widget_color: widget_color)
      return channel if channel.is_a?(String)

      inbox = account.inboxes.create!(name: name, channel: channel)
    end

    "Inbox created successfully.\n#{format_inbox(inbox)}"
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create inbox: #{e.record.errors.full_messages.join(', ')}"
  end

  private

  def create_channel(channel_type, website_url:, webhook_url:, widget_color:)
    case channel_type
    when 'api'
      account.api_channels.create!(webhook_url: webhook_url)
    when 'web_widget'
      return 'website_url is required for web_widget inboxes' if website_url.blank?

      account.web_widgets.create!(
        website_url: website_url,
        widget_color: widget_color.presence || '#1f93ff'
      )
    end
  end
end
