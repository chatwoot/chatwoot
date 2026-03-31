class EvolutionGo::ProvisionService
  pattr_initialize [:channel!]

  def perform
    ensure_supported_channel!

    client.ensure_instance!
    EvolutionGo::SyncStateService.new(channel: channel).perform
  end

  def cancel_pairing
    ensure_supported_channel!

    client.delete_instance
    reset_pairing_state!
  end

  def teardown
    ensure_supported_channel!

    client.delete_instance
  rescue EvolutionGo::Client::Error, EvolutionGo::Client::ConfigurationError => e
    Rails.logger.warn "[EVOLUTION_GO] Instance teardown failed for #{channel.id}: #{e.message}"
  end

  private

  def client
    @client ||= EvolutionGo::Client.new(channel: channel)
  end

  def reset_pairing_state!
    provider_config = current_provider_config.merge(
      'instance_name' => next_instance_name,
      'connection_status' => 'not_created'
    ).except(
      'instance_id',
      'jid',
      'connected',
      'logged_in',
      'qr_code',
      'pairing_code'
    )

    # rubocop:disable Rails/SkipsModelValidations
    channel.update_columns(
      provider_config: provider_config,
      phone_number: nil,
      updated_at: Time.current
    )
    # rubocop:enable Rails/SkipsModelValidations

    channel.provider_config = provider_config
    channel.phone_number = nil
  end

  def current_provider_config
    channel.provider_config.to_h.deep_stringify_keys
  end

  def next_instance_name
    "chatwit-#{channel.account_id}-#{SecureRandom.hex(6)}"
  end

  def ensure_supported_channel!
    return if channel.provider == 'evolution_go'

    raise ArgumentError, 'Evolution Go can only be provisioned for WhatsApp channels with provider evolution_go'
  end
end
