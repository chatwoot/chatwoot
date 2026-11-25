# frozen_string_literal: true

# An installation configures one brand, in ENV or in the super admin, and that is the right
# shape for a single-tenant install. It is the wrong shape for one that hosts several
# companies: every account's email then goes out wearing the same name, colour and logo,
# including the accounts that belong to somebody else.
#
# Brand resolves the brand an email should wear. An account overrides the installation field
# by field -- setting only a colour keeps the installation's name and logo -- so an install
# that configures nothing behaves exactly as it did before.
#
# The scope is what the customer sees: email, and the public pages a contact of that account
# opens. #config serves the mail layouts, #web_config serves those pages. The dashboard, the
# login page, the favicon, the PWA manifest and the widget are the installation's own
# surfaces and stay global; see CUSTOM_BRANDING.md.
class Brand
  # Published contract: layouts that customers already stored in email_templates read this
  # hash as `global_config`, so adding a key here changes what those layouts see. Keys the
  # mail layouts have no use for belong in WEB_KEYS instead.
  INSTALLATION_KEYS = %w[BRAND_NAME BRAND_URL BRAND_COLOR LOGO_EMAIL LOGO].freeze

  # The public pages want a different set: a small thumbnail for the footer, the widget's
  # brand URL, and a logo that may be a vector, since a browser renders what email cannot.
  WEB_KEYS = %w[BRAND_NAME BRAND_COLOR WIDGET_BRAND_URL LOGO_THUMBNAIL INSTALLATION_NAME].freeze

  # Email clients render none of the vector formats, so a logo that is not one of these puts a
  # broken image at the top of every email, which reads worse than the no-logo layout.
  EMAIL_SAFE_LOGO_FORMATS = %w[.png .jpg .jpeg .gif].freeze

  # inbox is accepted and unused: EmailTemplates::DbResolverService already resolves the email
  # layout inbox-first, and the brand inside that layout will want the same chain the day an
  # inbox needs its own. Taking it now keeps that from being a signature change later.
  def self.for(account: nil, inbox: nil)
    new(account: account, inbox: inbox)
  end

  def initialize(account: nil, inbox: nil)
    @account = account
    @inbox = inbox
  end

  # Keyed like the installation config on purpose. A branded layout already stored in
  # email_templates reads `global_config['BRAND_NAME']`, and those layouts belong to customers,
  # not to us -- they keep working and quietly start showing the account's own values.
  def config
    installation.merge(
      'BRAND_NAME' => name,
      'BRAND_URL' => url,
      'BRAND_COLOR' => color
    )
  end

  def name
    override(:brand_name) || installation['BRAND_NAME']
  end

  def url
    override(:brand_url) || installation['BRAND_URL']
  end

  def color
    override(:brand_color) || installation['BRAND_COLOR']
  end

  # Absolute, because an email is read outside the installation and a relative src resolves
  # against nothing.
  def logo_url
    account_logo_url || absolute_url(installation_logo)
  end

  # Keyed like the installation config, same as #config, so the page reads one shape whether
  # the brand came from the account or from the installation.
  def web_config
    web_installation.merge(
      'BRAND_NAME' => name,
      # The account's own brand_url, but falling back to WIDGET_BRAND_URL rather than to
      # BRAND_URL: that is the link this page already carries, and an install that points the
      # two at different places meant the difference.
      'WIDGET_BRAND_URL' => override(:brand_url) || web_installation['WIDGET_BRAND_URL'],
      'LOGO_THUMBNAIL' => account_logo_url || web_installation['LOGO_THUMBNAIL'],
      # Only ever the account's own logo. Falling back to the installation's would put one
      # company's mark on top of another company's page, and today the page simply shows no
      # logo in that case, which is the honest thing to keep doing.
      'BRAND_LOGO_URL' => account_logo_url.to_s,
      'BRAND_COLOR' => BrandColor.surface(color),
      # Darkened to 4.5:1 against white. Contrast is symmetric, so the same value is also what
      # makes white label text on top of it legible -- no second colour to compute.
      'BRAND_COLOR_STRONG' => BrandColor.on_light(color),
      # Whether the name above is the account's own or the installation's. #name alone cannot
      # answer that -- it falls back -- and the page needs the difference: an account with no
      # brand of its own has to keep rendering exactly what it rendered before.
      'BRAND_FROM_ACCOUNT' => override(:brand_name).present?
    )
  end

  private

  attr_reader :account, :inbox

  def installation
    @installation ||= GlobalConfig.get(*INSTALLATION_KEYS)
  end

  def web_installation
    @web_installation ||= GlobalConfig.get(*WEB_KEYS)
  end

  # Blank falls back rather than meaning "no name", which is what the settings screen promises
  # of an empty field. It also keeps an administrator who opens that screen and saves it
  # untouched from stripping the brand out of every email the account sends: the form posts
  # empty strings, not nils.
  def override(key)
    return nil unless overridable?

    account.public_send(key).presence
  end

  def overridable?
    account.present? && account.feature_enabled?(:branded_email_templates)
  end

  def account_logo_url
    return nil unless overridable?
    return nil unless account.brand_logo_email.attached?

    Rails.application.routes.url_helpers.rails_blob_url(account.brand_logo_email)
  end

  # Falling back to LOGO covers the installation that already has a raster logo without asking
  # it to configure a second one, and is guarded on the extension because LOGO is an SVG by
  # default.
  def installation_logo
    return installation['LOGO_EMAIL'] if installation['LOGO_EMAIL'].present?

    logo = installation['LOGO'].to_s
    logo if email_safe?(logo)
  end

  def email_safe?(path)
    extension = path.to_s.split('?').first.to_s.downcase
    EMAIL_SAFE_LOGO_FORMATS.any? { |format| extension.end_with?(format) }
  end

  def absolute_url(path)
    value = path.to_s.strip
    return value if value.blank? || value.start_with?('http://', 'https://')

    "#{ENV.fetch('FRONTEND_URL', nil).to_s.chomp('/')}/#{value.delete_prefix('/')}"
  end
end
