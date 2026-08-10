class Telegram::BusinessConnectionService
  USER_FIELDS = %w[id first_name last_name username].freeze
  CONNECTION_FIELDS = %w[id user_chat_id date is_enabled].freeze
  RIGHTS_FIELDS = %w[
    can_reply can_read_messages can_delete_sent_messages can_delete_all_messages
    can_edit_name can_edit_bio can_edit_profile_photo can_edit_username
    can_change_gift_settings can_view_gifts_and_stars can_convert_gifts_to_stars
    can_transfer_and_upgrade_gifts can_transfer_stars can_manage_stories
  ].freeze

  pattr_initialize [:channel!]

  def process(connection_params)
    connection = normalize_connection(connection_params)
    return persist_error('Invalid Telegram Business connection payload') if connection['id'].blank?

    channel.with_lock do
      config = channel.business_config.deep_dup
      config['can_connect_to_business'] = true
      config['connections'] ||= {}
      config['connections'][connection['id']] = connection

      persist_config(config)
    end
  end

  def sync(connection_id)
    return if connection_id.blank? || known_enabled_connection?(connection_id)

    response = HTTParty.get(
      "#{channel.telegram_api_url}/getBusinessConnection",
      query: { business_connection_id: connection_id }
    )
    payload = response.parsed_response
    return process(payload['result']) if response.success? && payload['ok'] == true

    persist_error(payload['description'].presence || 'Unable to fetch Telegram Business connection')
  rescue StandardError => e
    persist_error(e.message)
  end

  private

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

  def persist_config(config)
    error = 'Multiple active Telegram Business connections detected' if active_connection_count(config) > 1
    update_channel(
      business_config: config,
      business_config_checked_at: Time.current,
      business_config_error: error
    )
  end

  def active_connection_count(config)
    config.fetch('connections', {}).count { |_id, connection| connection['is_enabled'] == true }
  end

  def persist_error(error)
    update_channel(
      business_config_checked_at: Time.current,
      business_config_error: error.to_s.truncate(500)
    )
  end

  def update_channel(attributes)
    # Provider state updates must not revalidate the token or re-register the webhook.
    # rubocop:disable Rails/SkipsModelValidations
    channel.update_columns(attributes)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
