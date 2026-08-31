class SocialChannels::ProviderNameBackfillService
  PROVIDERS = {
    instagram: Channel::Instagram,
    tiktok: Channel::Tiktok,
    facebook: Channel::FacebookPage
  }.freeze
  RETRYABLE_HTTP_STATUSES = [429, 500, 502, 503, 504].freeze

  def initialize(**options)
    @account_id = options[:account_id].presence&.to_i
    @provider_names = options[:provider].present? ? [options[:provider].to_sym] : PROVIDERS.keys
    @limit = options[:limit].presence&.to_i
    @delay_seconds = options.fetch(:delay_seconds, 1).to_f
    @dry_run = options.fetch(:dry_run, true)
    @output = options.fetch(:output, $stdout)
    @sleeper = options.fetch(:sleeper, Kernel.method(:sleep))

    validate_options!
  end

  def perform
    enumerators = @provider_names.index_with { |provider_name| eligible_scope(provider_name).find_each }
    summary = @provider_names.index_with { empty_summary }
    process_enumerators(enumerators, summary)

    print_summary(summary)
    summary
  end

  private

  def process_enumerators(enumerators, summary)
    processed = 0

    processed += process_round(enumerators, summary, processed) until enumerators.empty? || limit_reached?(processed)
  end

  def process_round(enumerators, summary, already_processed)
    processed = 0

    enumerators.each_key.to_a.each do |provider_name|
      break if limit_reached?(already_processed + processed)

      channel = next_channel(enumerators, provider_name)
      next unless channel

      process_candidate(provider_name, channel, summary[provider_name])
      processed += 1
    end

    processed
  end

  def process_candidate(provider_name, channel, provider_summary)
    provider_summary[:eligible] += 1
    process_channel(provider_name, channel, provider_summary) unless @dry_run
    print_dry_run(provider_name, channel) if @dry_run
  end

  def limit_reached?(processed)
    @limit && processed >= @limit
  end

  def validate_options!
    unknown_providers = @provider_names - PROVIDERS.keys
    raise ArgumentError, "Unknown provider: #{unknown_providers.join(', ')}" if unknown_providers.any?
    raise ArgumentError, 'LIMIT must be greater than zero' if @limit && @limit <= 0
    raise ArgumentError, 'DELAY_SECONDS cannot be negative' if @delay_seconds.negative?
  end

  def eligible_scope(provider_name)
    scope = PROVIDERS.fetch(provider_name)
                     .joins(:account, :inbox)
                     .merge(Account.active)
                     .where(provider_name: [nil, ''])
    @account_id ? scope.where(account_id: @account_id) : scope
  end

  def next_channel(enumerators, provider_name)
    enumerators.fetch(provider_name).next
  rescue StopIteration
    enumerators.delete(provider_name)
    nil
  end

  def process_channel(provider_name, channel, provider_summary)
    provider_summary[:attempted] += 1
    provider_name_value = with_retries { fetch_provider_name(provider_name, channel) }

    if provider_name_value.blank?
      provider_summary[:skipped] += 1
      @output.puts "[skipped] provider=#{provider_name} channel_id=#{channel.id} account_id=#{channel.account_id} reason=blank_name"
    else
      channel.update!(provider_name: provider_name_value)
      provider_summary[:updated] += 1
      @output.puts "[updated] provider=#{provider_name} channel_id=#{channel.id} account_id=#{channel.account_id}"
    end
  rescue StandardError => e
    result = authentication_error?(e) ? :skipped : :failed
    provider_summary[result] += 1
    @output.puts "[#{result}] provider=#{provider_name} channel_id=#{channel.id} account_id=#{channel.account_id} error=#{e.class.name}"
  ensure
    @sleeper.call(@delay_seconds) if @delay_seconds.positive?
  end

  def fetch_provider_name(provider_name, channel)
    case provider_name
    when :instagram
      Instagram::UserDetailsService.new(access_token: channel.access_token).perform['username']
    when :tiktok
      Tiktok::Client.new(business_id: channel.business_id, access_token: channel.validated_access_token)
                    .business_account_details[:username]
    when :facebook
      Facebook::PageDetailsService.new(access_token: channel.page_access_token).perform[:provider_name]
    end
  end

  def with_retries
    retries = 0

    begin
      yield
    rescue StandardError => e
      raise unless retryable_error?(e) && retries < 2

      @sleeper.call(@delay_seconds * (2**retries)) if @delay_seconds.positive?
      retries += 1
      retry
    end
  end

  def retryable_error?(error)
    return true if defined?(Koala::Facebook::ServerError) && error.is_a?(Koala::Facebook::ServerError)

    RETRYABLE_HTTP_STATUSES.include?(error_status(error))
  end

  def authentication_error?(error)
    return true if defined?(Koala::Facebook::AuthenticationError) && error.is_a?(Koala::Facebook::AuthenticationError)

    [401, 403].include?(error_status(error)) || error.message.to_s.match?(/["']code["']\s*:\s*190\b/)
  end

  def error_status(error)
    return error.http_status.to_i if error.respond_to?(:http_status)

    error.message.to_s[/\A(\d{3}):/, 1].to_i
  end

  def print_dry_run(provider_name, channel)
    @output.puts "[dry-run] provider=#{provider_name} channel_id=#{channel.id} account_id=#{channel.account_id}"
  end

  def print_summary(summary)
    summary.each do |provider_name, counts|
      @output.puts "[summary] provider=#{provider_name} #{counts.map { |key, value| "#{key}=#{value}" }.join(' ')}"
    end
  end

  def empty_summary
    { eligible: 0, attempted: 0, updated: 0, skipped: 0, failed: 0 }
  end
end
