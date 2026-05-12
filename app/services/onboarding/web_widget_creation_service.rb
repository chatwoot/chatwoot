class Onboarding::WebWidgetCreationService
  DEFAULT_WIDGET_COLOR = '#1f93ff'.freeze
  # context.dev descriptions and LLM completions are unbounded; bound the
  # stored tagline so a long string doesn't render as a wall of text in the
  # widget UI (and so backends that enforce varchar limits don't raise).
  WELCOME_TAGLINE_MAX_LENGTH = 255

  def initialize(account, user)
    @account = account
    @user = user
  end

  def perform
    existing = existing_web_widget_inbox
    if existing
      Rails.logger.info "[WidgetCreation] Reusing existing web widget inbox #{existing.id} for account #{@account.id}"
      return existing
    end

    if website_url.blank?
      Rails.logger.info "[WidgetCreation] Skipping for account #{@account.id}: no website_url available"
      return nil
    end

    attrs = channel_attributes

    ActiveRecord::Base.transaction do
      channel = @account.web_widgets.create!(attrs)
      inbox = @account.inboxes.create!(name: @account.name, channel: channel)
      InboxMember.find_or_create_by!(inbox: inbox, user: @user)
      inbox
    end
  rescue StandardError => e
    Rails.logger.error "[WidgetCreation] #{e.message}"
    nil
  end

  private

  def existing_web_widget_inbox
    @account.inboxes.find_by(channel_type: 'Channel::WebWidget')
  end

  def channel_attributes
    {
      website_url: website_url,
      widget_color: widget_color,
      welcome_title: welcome_title,
      welcome_tagline: welcome_tagline_text&.truncate(WELCOME_TAGLINE_MAX_LENGTH)
    }
  end

  def brand_info
    @brand_info ||= (@account.custom_attributes['brand_info'] || {}).deep_symbolize_keys
  end

  def website_url
    @account.domain.presence || brand_info[:domain].presence
  end

  def widget_color
    hex = brand_info[:colors]&.first&.dig(:hex)
    hex.to_s.match?(/\A#\h{6}\z/) ? hex : DEFAULT_WIDGET_COLOR
  end

  def welcome_title
    brand_info[:title].presence || @account.name
  end

  def welcome_tagline_text
    brand_info[:slogan].presence || brand_info[:description].presence
  end
end

Onboarding::WebWidgetCreationService.prepend_mod_with('Onboarding::WebWidgetCreationService')
