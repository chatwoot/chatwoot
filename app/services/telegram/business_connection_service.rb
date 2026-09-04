class Telegram::BusinessConnectionService
  USER_FIELDS = %w[id first_name last_name username].freeze
  CONNECTION_FIELDS = %w[id user_chat_id date is_enabled].freeze
  RIGHTS_FIELDS = %w[
    can_reply can_read_messages can_delete_sent_messages can_delete_all_messages
    can_edit_name can_edit_bio can_edit_profile_photo can_edit_username
    can_change_gift_settings can_view_gifts_and_stars can_convert_gifts_to_stars
    can_transfer_and_upgrade_gifts can_transfer_stars can_manage_stories
  ].freeze

  attr_reader :channel, :expected_bot_token

  def initialize(channel:)
    @channel = channel
    @expected_bot_token = channel.bot_token
  end

  def process(connection_params, update_id: nil, expected_bot_token: self.expected_bot_token, expected_update_id: nil)
    connection = normalize_connection(connection_params)
    return persist_error('Invalid Telegram Business connection payload', expected_bot_token: expected_bot_token) if connection['id'].blank?

    persist_connection(connection, update_id: update_id, expected_bot_token: expected_bot_token, expected_update_id: expected_update_id)
  end

  def sync(connection_id, update_id: nil)
    request_bot_token = expected_bot_token
    return if connection_id.blank? || known_enabled_connection?(connection_id)

    expected_update_id = channel.business_config.dig('connections', connection_id, 'update_id')
    response = HTTParty.get(
      "https://api.telegram.org/bot#{request_bot_token}/getBusinessConnection",
      query: { business_connection_id: connection_id }
    )
    payload = response.parsed_response
    if response.success? && payload['ok'] == true
      return process(payload['result'], update_id: update_id, expected_bot_token: request_bot_token, expected_update_id: expected_update_id)
    end

    error = payload['description'].presence || 'Unable to fetch Telegram Business connection'
    persist_sync_error(error, connection_id, request_bot_token, expected_update_id)
  rescue StandardError => e
    persist_sync_error(e.message, connection_id, request_bot_token, expected_update_id)
  end

  def observe_update(update_id)
    return if update_id.blank?

    channel.with_lock do
      next false unless channel.bot_token == expected_bot_token

      config = channel.business_config.deep_dup
      next false if config.fetch('connections', {}).empty? || !record_update(config, update_id)

      update_channel(business_config: config)
    end
  end

  private

  def persist_connection(connection, update_id:, expected_bot_token:, expected_update_id:)
    channel.with_lock do
      config = channel.business_config.deep_dup
      config['can_connect_to_business'] = true
      config['connections'] ||= {}
      next false unless applicable_update?(config, connection['id'], update_id, expected_bot_token, expected_update_id)
      next if stale_connection_update?(config, connection['id'], update_id)

      apply_update_ordering(connection, update_id, expected_update_id)
      config['connections'][connection['id']] = connection
      record_update(config, update_id)

      persist_config(config)
    end
  end

  def applicable_update?(config, connection_id, update_id, expected_bot_token, expected_update_id)
    return false unless channel.bot_token == expected_bot_token
    return true if update_id.present?

    connection_update_id(config, connection_id) == expected_update_id
  end

  def normalize_connection(connection_params)
    params = connection_params.to_h.with_indifferent_access
    connection = params.slice(*CONNECTION_FIELDS)
    connection['user'] = params[:user].to_h.with_indifferent_access.slice(*USER_FIELDS)
    connection['rights'] = params[:rights].to_h.with_indifferent_access.slice(*RIGHTS_FIELDS)
    connection.stringify_keys
  end

  def known_enabled_connection?(connection_id)
    channel.business_config.dig('connections', connection_id, 'is_enabled') == true
  end

  def stale_connection_update?(config, connection_id, update_id)
    previous_update_id = connection_update_id(config, connection_id)
    return false if update_id.blank? || previous_update_id.blank? || update_ids_expired?(config)

    update_id <= previous_update_id
  end

  def apply_update_ordering(connection, update_id, expected_update_id)
    ordering_update_id = update_id.presence || expected_update_id
    return if ordering_update_id.blank?

    connection['update_id'] = ordering_update_id
  end

  def record_update(config, update_id)
    return false if update_id.blank? || stale_observed_update?(config, update_id)

    config['last_update_id'] = update_id
    config['last_update_id_received_at'] = Time.current.to_i
    true
  end

  def stale_observed_update?(config, update_id)
    config['last_update_id'].present? && !update_ids_expired?(config) && update_id <= config['last_update_id']
  end

  def update_ids_expired?(config)
    config['last_update_id_received_at'].to_i <= 1.week.ago.to_i
  end

  def persist_config(config)
    error = Channel::Telegram::MULTIPLE_ACTIVE_CONNECTIONS_ERROR if active_connection_count(config) > 1
    update_channel(
      business_config: config,
      business_config_checked_at: Time.current,
      business_config_error: error
    )
  end

  def active_connection_count(config)
    config.fetch('connections', {}).count { |_id, connection| connection['is_enabled'] == true }
  end

  def persist_error(error, expected_bot_token: self.expected_bot_token, connection_id: nil, expected_update_id: nil)
    channel.with_lock do
      next false unless channel.bot_token == expected_bot_token
      next false if connection_id.present? && connection_update_id(channel.business_config, connection_id) != expected_update_id

      update_channel(
        business_config_checked_at: Time.current,
        business_config_error: error.to_s.truncate(500)
      )
    end
  end

  def persist_sync_error(error, connection_id, expected_bot_token, expected_update_id)
    persist_error(
      error,
      expected_bot_token: expected_bot_token,
      connection_id: connection_id,
      expected_update_id: expected_update_id
    )
  end

  def connection_update_id(config, connection_id)
    config.dig('connections', connection_id, 'update_id')
  end

  def update_channel(attributes)
    # Provider state updates must not revalidate the token or re-register the webhook.
    # rubocop:disable Rails/SkipsModelValidations
    channel.update_columns(attributes)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
