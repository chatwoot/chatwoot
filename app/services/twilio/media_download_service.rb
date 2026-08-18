class Twilio::MediaDownloadService
  RETRY_DELAYS = [1, 3].freeze
  API_HOST_PATTERN = /\Aapi(?:\.[a-z0-9-]+){0,2}\.twilio\.com\z/i
  IPV4_RESOLVER = lambda do |hostname|
    SsrfFilter::DEFAULT_RESOLVER.call(hostname).select(&:ipv4?)
  end

  pattr_initialize [:channel!, :media_url!, :message_sid!, :media_index!, { retry_delays: RETRY_DELAYS }] do
    @account_sid = channel.account_sid
    @auth_credentials = if channel.api_key_sid.present?
                          [channel.api_key_sid, channel.auth_token]
                        else
                          [account_sid, channel.auth_token]
                        end
  end

  attr_private :account_sid, :auth_credentials

  def perform
    return download_without_auth unless valid_retry_url?

    file = download_with_auth
    log_download(outcome: 'success', attempt: 1)
    file
  rescue SafeFetch::HttpError => e
    return retry_with_auth(e) if http_status(e) == 404

    log_failure(e, 1)
  rescue SafeFetch::Error => e
    log_failure(e, 1)
  end

  private

  def retry_with_auth(initial_error)
    last_error = initial_error
    attempt = 1

    while (delay = retry_delays.shift)
      attempt += 1
      begin
        return download_retry(delay, attempt, last_error)
      rescue SafeFetch::HttpError => e
        last_error = e
        return log_failure(e, attempt) unless http_status(e) == 404
      rescue SafeFetch::Error => e
        return log_failure(e, attempt)
      end
    end

    log_failure(last_error, attempt)
  end

  def download_retry(delay, attempt, error)
    log_download(outcome: 'retrying', attempt: attempt, error: error, delay: delay)
    sleep delay
    file = download_with_auth
    log_download(outcome: 'success', attempt: attempt)
    file
  end

  def download_with_auth
    SafeFetch.fetch(
      media_url,
      http_basic_authentication: auth_credentials,
      resolver: IPV4_RESOLVER,
      validate_content_type: false
    ) { |result| retain_download(result) }
  end

  def download_without_auth
    file = SafeFetch.fetch(media_url, validate_content_type: false) { |result| retain_download(result) }
    log_download(outcome: 'success_without_auth', attempt: 1)
    file
  rescue SafeFetch::Error => e
    retry_without_auth(e)
  end

  def retry_without_auth(initial_error)
    log_download(outcome: 'retrying_without_auth', attempt: 2, error: initial_error)
    file = SafeFetch.fetch(media_url, validate_content_type: false) { |result| retain_download(result) }
    log_download(outcome: 'success_without_auth', attempt: 2)
    file
  rescue SafeFetch::Error => e
    log_failure(e, 2)
  end

  def retain_download(result)
    filename = result.original_filename
    content_type = result.content_type

    result.tempfile.dup.tap do |file|
      file.define_singleton_method(:original_filename) { filename }
      file.define_singleton_method(:content_type) { content_type }
    end
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
    prefix = "/2010-04-01/Accounts/#{account_sid}/Messages/#{message_sid}/Media/"
    path.match?(/\A#{Regexp.escape(prefix)}ME[0-9a-f]{32}\z/i)
  end

  def http_status(error)
    error.message.to_s[/\A(\d{3})\b/, 1]&.to_i
  end

  def log_failure(error, attempt)
    log_download(outcome: 'skipped', attempt: attempt, error: error)
    nil
  end

  def log_download(outcome:, attempt:, error: nil, delay: nil)
    details = [
      '[TWILIO] Media download', "outcome=#{outcome}", "attempt=#{attempt}",
      ("delay=#{delay}s" if delay), "sms_sid=#{message_sid}", "account_id=#{channel.inbox.account_id}",
      "inbox_id=#{channel.inbox.id}", "media_index=#{media_index}", ("error=#{error.class.name}" if error),
      ("status=#{http_status(error)}" if error && http_status(error))
    ].compact.join(' ')

    Rails.logger.info(details)
  end
end
