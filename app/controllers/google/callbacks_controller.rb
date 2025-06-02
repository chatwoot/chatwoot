class Google::CallbacksController < OauthCallbackController
  include GoogleConcern

  def find_channel_by_email
    # find by imap_login first, and then by email
    # this ensures the legacy users can migrate correctly even if inbox email address doesn't match
    imap_channel = Channel::Email.find_by(imap_login: users_data['email'], account: account)
    return imap_channel if imap_channel

    Channel::Email.find_by(email: users_data['email'], account: account)
  end

  private

  def verify_scopes
    granted_scopes = parsed_body['scope']&.split || []
    required_scopes = scope.split

    missing_scopes = required_scopes - granted_scopes
    return if missing_scopes.empty?

    raise CustomExceptions::OAuth::InsufficientScopes.new({ missing_scopes: missing_scopes })
  end

  def provider_name
    'google'
  end

  def imap_address
    'imap.gmail.com'
  end

  def oauth_client
    # from GoogleConcern
    google_client
  end

  def handle_error(exception)
    ChatwootExceptionTracker.new(exception).capture_exception

    error_code = exception.respond_to?(:code) ? exception.code : 'OAUTH_ERR'
    error_message = exception.message || 'OAuth authorization failed'

    redirect_url = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/app/accounts/#{account.id}/settings/inboxes/new/email"
    redirect_to "#{redirect_url}?error=#{CGI.escape(error_message)}&code=#{error_code}"
  end
end
