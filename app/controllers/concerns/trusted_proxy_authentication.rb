# Auto-login for installations running behind a trusted authenticating proxy
# (e.g. Cloudflare Access sets Cf-Access-Authenticated-User-Email). The proxy is
# trusted to strip client-supplied values for this header, so its presence alone
# proves the user's identity; we exchange it for a short-lived SSO auth token that
# the login page submits automatically.
module TrustedProxyAuthentication
  extend ActiveSupport::Concern

  # Post-login continuation the dashboard router puts on /app/login (see
  # app/javascript/dashboard/routes/index.js); only values in the shapes it produces are kept.
  CONTINUATION_PARAM_FORMATS = {
    'sso_account_id' => /\A[1-9]\d*\z/,
    'sso_conversation_id' => /\A[1-9]\d*\z/,
    'shop' => Shopify::ShopDomain::FORMAT,
    'plan_handle' => /\A[a-zA-Z0-9_-]+\z/
  }.freeze
  SHOPIFY_INTEGRATION_REDIRECT_PATTERN = %r{\Asettings/integrations/shopify(?:\?shopify_pending_install=[0-9a-f]{32})?\z}
  SHOPIFY_BILLING_REDIRECT_PARAMS = %w[shop plan_handle].freeze

  private

  def process_trusted_proxy_auth
    return unless request.path == '/app/login'
    return if params[:sso_auth_token].present?
    return unless trusted_proxy_auth_enabled?

    email = request.headers[trusted_proxy_auth_header]
    return if email.blank?

    user = User.from_email(email.strip)
    return if user.blank?
    return unless confirm_trusted_proxy_user(user)

    redirect_to "/app/login?#{trusted_proxy_login_query(user)}"
  end

  # Pre-encode the email before to_query, matching the OAuth callback: the router decodes
  # the query once and the login page calls decodeURIComponent on the email again.
  def trusted_proxy_login_query(user)
    {
      'email' => ERB::Util.url_encode(user.email),
      'sso_auth_token' => user.generate_sso_auth_token
    }.merge(trusted_proxy_continuation_params).to_query
  end

  def trusted_proxy_continuation_params
    continuation = CONTINUATION_PARAM_FORMATS.each_with_object({}) do |(key, format), kept|
      value = params[key]
      kept[key] = value if value.is_a?(String) && value.match?(format)
    end
    redirect_url = params[:redirect_url]
    continuation['redirect_url'] = redirect_url if redirect_url.is_a?(String) && trusted_proxy_redirect_url?(redirect_url)
    continuation
  end

  def trusted_proxy_redirect_url?(redirect_url)
    return true if redirect_url.match?(SHOPIFY_INTEGRATION_REDIRECT_PATTERN)

    path, query = redirect_url.split('?', 2)
    return false unless path == 'settings/billing' && query.present?

    pairs = URI.decode_www_form(query)
    pairs.any? && pairs.map(&:first).uniq.size == pairs.size &&
      pairs.all? { |key, value| SHOPIFY_BILLING_REDIRECT_PARAMS.include?(key) && CONTINUATION_PARAM_FORMATS[key].match?(value) }
  rescue ArgumentError
    false
  end

  # The proxy has verified the email, so treat it like the OAuth callback does: confirm a
  # pending invitee (the SSO session flow never checks confirmation, and unconfirmed users
  # are skipped by notifications and assignment) and rotate the password so one set before
  # confirmation, e.g. by someone who pre-registered the address, can no longer be used.
  def confirm_trusted_proxy_user(user)
    return true if user.confirmed?

    user.skip_confirmation!
    user.password = "#{SecureRandom.hex(16)}aA1!"
    user.save
  end

  # Plain ENV reads (no InstallationConfig): the env var stays authoritative on every
  # boot instead of being frozen into the DB by the first request that reads it.
  def trusted_proxy_auth_enabled?
    ENV.fetch('ENABLE_TRUSTED_PROXY_AUTH', 'false') == 'true'
  end

  def trusted_proxy_auth_header
    ENV.fetch('TRUSTED_PROXY_AUTH_HEADER', 'Cf-Access-Authenticated-User-Email')
  end

  def trusted_proxy_logout_redirect_link
    ENV.fetch('TRUSTED_PROXY_LOGOUT_REDIRECT_LINK', '/cdn-cgi/access/logout')
  end
end
