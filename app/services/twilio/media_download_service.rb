class Twilio::MediaDownloadService
  RETRY_DELAYS = [1, 3].freeze
  API_HOST_PATTERN = /\Aapi(?:\.[a-z0-9-]+){0,2}\.twilio\.com\z/i

  pattr_initialize [:channel!, :media_url!, :message_sid!, :media_index!]

  def perform
    return download_without_auth unless valid_retry_url?

    download_with_auth
  rescue Down::NotFound => e
    retry_with_auth(e)
  rescue Down::Error => e
    log_failure(e, 1)
  end

  private

  def retry_with_auth(initial_error)
    last_error = initial_error

    RETRY_DELAYS.each_with_index do |delay, index|
      return download_retry(delay, index + 2, last_error)
    rescue Down::NotFound => e
      last_error = e
    rescue Down::Error => e
      return log_failure(e, index + 2)
    end

    log_failure(last_error, RETRY_DELAYS.length + 1)
  end

  def download_retry(delay, attempt, error)
    log_download(outcome: 'retrying', attempt: attempt, error: error, delay: delay)
    sleep delay
    file = download_with_auth
    log_download(outcome: 'success', attempt: attempt)
    file
  end

  def download_with_auth
    Down.download(media_url, http_basic_authentication: auth_credentials)
  end

  def auth_credentials
    return [channel.api_key_sid, channel.auth_token] if channel.api_key_sid.present?

    [channel.account_sid, channel.auth_token]
  end

  def download_without_auth
    file = Down.download(media_url)
    log_download(outcome: 'success_without_auth', attempt: 1)
    file
  rescue StandardError => e
    retry_without_auth(e)
  end

  def retry_without_auth(initial_error)
    log_download(outcome: 'retrying_without_auth', attempt: 2, error: initial_error)
    file = Down.download(media_url)
    log_download(outcome: 'success_without_auth', attempt: 2)
    file
  rescue StandardError => e
    log_failure(e, 2)
  end

  def valid_retry_url?
    uri = URI.parse(media_url)
    secure_twilio_api_uri?(uri) && valid_media_path?(uri.path)
  rescue URI::InvalidURIError
    false
  end

  def secure_twilio_api_uri?(uri)
    return false unless uri.is_a?(URI::HTTPS)
    return false unless uri.host&.match?(API_HOST_PATTERN)
    return false if uri.userinfo.present? || uri.port != 443

    uri.query.blank? && uri.fragment.blank?
  end

  def valid_media_path?(path)
    prefix = "/2010-04-01/Accounts/#{channel.account_sid}/Messages/#{message_sid}/Media/"
    path.match?(/\A#{Regexp.escape(prefix)}ME[0-9a-f]{32}\z/i)
  end

  def log_failure(error, attempt)
    log_download(outcome: 'skipped', attempt: attempt, error: error)
    nil
  end

  def log_download(outcome:, attempt:, error: nil, delay: nil)
    details = [
      '[TWILIO] Media download', "outcome=#{outcome}", "attempt=#{attempt}",
      ("delay=#{delay}s" if delay), "sms_sid=#{message_sid}", "account_id=#{channel.inbox.account_id}",
      "inbox_id=#{channel.inbox.id}", "media_index=#{media_index}", ("error=#{error.class.name}" if error)
    ].compact.join(' ')

    Rails.logger.info(details)
  end
end
