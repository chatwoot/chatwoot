class Onboarding::HelpCenterCreationService
  DEFAULT_PORTAL_COLOR = '#1f93ff'.freeze
  LOGO_MAX_DOWNLOAD_SIZE = 5.megabytes

  def initialize(account, user)
    @account = account
    @user = user
  end

  def perform
    existing = existing_portal
    return reuse_existing_portal(existing) if existing

    @account.portals.create!(portal_attributes).tap do |portal|
      attach_brand_logo(portal)
      enqueue_article_generation(portal)
    end
  end

  private

  def existing_portal
    @account.portals.first
  end

  def reuse_existing_portal(portal)
    Rails.logger.info "[HelpCenterCreation] Reusing existing portal #{portal.id} for account #{@account.id}"
    portal
  end

  def portal_attributes
    {
      name: portal_name,
      slug: generate_slug,
      color: portal_color,
      page_title: portal_name,
      header_text: header_text,
      homepage_link: homepage_link,
      channel_web_widget_id: web_widget_channel_id,
      config: { default_locale: locale, allowed_locales: [locale] }
    }.compact
  end

  def brand_info
    @brand_info ||= (@account.custom_attributes['brand_info'] || {}).deep_symbolize_keys
  end

  def portal_name
    brand_info[:title].presence || @account.name
  end

  def portal_color
    hex = brand_info[:colors]&.first&.dig(:hex)
    hex.to_s.match?(/\A#\h{6}\z/) ? hex : DEFAULT_PORTAL_COLOR
  end

  def header_text
    brand_info[:slogan].presence || brand_info[:description].presence
  end

  def homepage_link
    with_scheme(custom_attributes_website.presence || brand_info[:domain].presence)
  end

  def with_scheme(raw)
    return raw if raw.blank?

    raw.match?(%r{\Ahttps?://}i) ? raw : "https://#{raw}"
  end

  def custom_attributes_website
    @account.custom_attributes['website']
  end

  def enqueue_article_generation(portal)
    return if homepage_link.blank?

    generation_id = SecureRandom.uuid
    Onboarding::HelpCenterArticleGenerationJob.perform_later(@account.id, portal.id, @user.id, generation_id)
    @account.update!(custom_attributes: @account.custom_attributes.merge('help_center_generation_id' => generation_id))
  rescue StandardError => e
    Rails.logger.error "[HelpCenterCreation] Failed to enqueue article generation for account #{@account.id}: #{e.class} - #{e.message}"
  end

  def attach_brand_logo(portal)
    logo_url = brand_logo_url
    return if logo_url.blank?

    SafeFetch.fetch(logo_url, max_bytes: LOGO_MAX_DOWNLOAD_SIZE, allowed_content_type_prefixes: ['image/']) do |logo_file|
      portal.logo.attach(
        io: logo_file.tempfile,
        filename: logo_file.original_filename,
        content_type: logo_file.content_type
      )
    end
  rescue StandardError => e
    Rails.logger.error "[HelpCenterCreation] Logo attachment failed for account #{@account.id}: #{e.class} - #{e.message}"
  end

  def brand_logo_url
    Array(brand_info[:logos]).filter_map do |logo|
      logo.is_a?(Hash) ? logo[:url] : logo
    end.find(&:present?)
  end

  def web_widget_channel_id
    @account.inboxes.find_by(channel_type: 'Channel::WebWidget')&.channel_id
  end

  def locale
    @account.locale.presence || 'en'
  end

  def generate_slug
    slug_candidates.find { |slug| !Portal.exists?(slug: slug) } || fallback_slug
  end

  def slug_candidates
    base = @account.name.to_s.parameterize.presence
    return [] if base.blank?

    first_token = base.split('-').first
    [base, first_token, "#{first_token}-docs", "#{first_token}-help"].uniq
  end

  def fallback_slug
    base = @account.name.to_s.parameterize.presence || 'portal'
    "#{base}-#{SecureRandom.hex(4)}"
  end
end
