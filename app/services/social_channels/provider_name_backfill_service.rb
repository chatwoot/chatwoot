class SocialChannels::ProviderNameBackfillService
  PROVIDERS = {
    instagram: Channel::Instagram,
    tiktok: Channel::Tiktok,
    facebook: Channel::FacebookPage
  }.freeze
  RETRYABLE_HTTP_STATUSES = [429, 500, 502, 503, 504].freeze

  def initialize(**options)
    @account_id = parse_integer_option(options[:account_id], 'ACCOUNT_ID', minimum: 1)
    @provider_name = options[:provider].presence&.to_sym
    @provider_names = @provider_name ? [@provider_name] : PROVIDERS.keys
    @limit = parse_integer_option(options[:limit], 'LIMIT', minimum: 1)
    @after_id = parse_integer_option(options[:after_id], 'AFTER_ID', minimum: 0)
    @delay_seconds = parse_delay_seconds(options.fetch(:delay_seconds, 1))
    @dry_run = options.fetch(:dry_run, true)
    @output = options.fetch(:output, $stdout)
    @sleeper = options.fetch(:sleeper, Kernel.method(:sleep))

    validate_options!
  end

  def perform
    enumerators = @provider_names.index_with { |provider_name| eligible_scope(provider_name).find_each }
    summary = @provider_names.index_with { empty_summary }
    process_enumerators(enumerators, summary)
    populate_remaining_counts(summary)

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
    if @dry_run
      print_dry_run(provider_name, channel)
    else
      provider_summary[:last_attempted_id] = channel.id
      process_channel(provider_name, channel, provider_summary)
    end
  end

  def limit_reached?(processed)
    @limit && processed >= @limit
  end

  def validate_options!
    unknown_providers = @provider_names - PROVIDERS.keys
    raise ArgumentError, "Unknown provider: #{unknown_providers.join(', ')}" if unknown_providers.any?
    raise ArgumentError, 'PROVIDER is required when LIMIT is set' if @limit && @provider_name.nil?
    raise ArgumentError, 'PROVIDER is required when AFTER_ID is set' if @after_id && @provider_name.nil?
  end

  def eligible_scope(provider_name)
    scope = base_eligible_scope(provider_name)
    scope = scope.where(PROVIDERS.fetch(provider_name).arel_table[:id].gt(@after_id)) if @after_id
    scope
  end

  def base_eligible_scope(provider_name)
    scope = PROVIDERS.fetch(provider_name).joins(:account, :inbox).merge(Account.active).where(provider_name: [nil, ''])
    @account_id ? scope.where(account_id: @account_id) : scope
  end

  def populate_remaining_counts(summary)
    @provider_names.each do |provider_name|
      summary[provider_name][:remaining] = base_eligible_scope(provider_name).count
    end
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
    { eligible: 0, attempted: 0, updated: 0, skipped: 0, failed: 0, remaining: 0, last_attempted_id: nil }
  end

  def parse_integer_option(value, name, minimum:)
    return if value.blank?

    parsed_value = value.is_a?(String) ? Integer(value, 10) : value
    raise ArgumentError unless parsed_value.is_a?(Integer)
    return parsed_value if parsed_value >= minimum

    raise ArgumentError
  rescue ArgumentError, TypeError
    qualifier = minimum.zero? ? 'a non-negative integer' : 'a positive integer'
    raise ArgumentError, "#{name} must be #{qualifier}"
  end

  def parse_delay_seconds(value)
    parsed_value = Float(value)
    return parsed_value if parsed_value.finite? && parsed_value >= 0

    raise ArgumentError
  rescue ArgumentError, TypeError
    raise ArgumentError, 'DELAY_SECONDS must be a finite non-negative number'
  end
end
