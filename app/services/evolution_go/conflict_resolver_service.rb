class EvolutionGo::ConflictResolverService
  class Error < StandardError; end

  REUSE = 'reuse'.freeze
  REPLACE = 'replace'.freeze
  STRATEGIES = [REUSE, REPLACE].freeze

  pattr_initialize [:channel!, :strategy!]

  def perform
    raise Error, 'Invalid strategy' unless STRATEGIES.include?(strategy)
    raise Error, 'No phone conflict to resolve' if conflict_info.blank?
    raise Error, 'Conflicting inbox not found' if conflict_inbox.blank?
    raise Error, 'Cannot resolve conflict across accounts' unless conflict_info['same_account']

    strategy == REUSE ? resolve_reuse : resolve_replace
  end

  private

  def conflict_info
    @conflict_info ||= channel.provider_config.to_h.with_indifferent_access[:phone_conflict]
  end

  def conflict_inbox
    @conflict_inbox ||= Inbox.find_by(
      id: conflict_info['conflicting_inbox_id'],
      account_id: conflict_info['conflicting_account_id']
    )
  end

  def resolve_reuse
    EvolutionGo::ProvisionService.new(channel: channel).teardown
    inbox = channel.inbox
    inbox.destroy!
    {
      'strategy' => REUSE,
      'redirect_inbox_id' => conflict_inbox.id,
      'redirect_account_id' => conflict_inbox.account_id
    }
  end

  def resolve_replace
    conflicting_phone = conflict_info['phone_number']

    ActiveRecord::Base.transaction do
      retire_conflicting_channel!
      assign_phone_to_current_channel!(conflicting_phone)
    end

    {
      'strategy' => REPLACE,
      'phone_number' => conflicting_phone,
      'retired_inbox_id' => conflict_inbox.id
    }
  end

  def retire_conflicting_channel!
    old_channel = conflict_inbox.channel
    EvolutionGo::ProvisionService.new(channel: old_channel).teardown if old_channel.is_a?(Channel::Whatsapp) && old_channel.provider == 'evolution_go'

    old_provider_config = old_channel.provider_config.to_h.deep_stringify_keys.merge(
      'connection_status' => 'retired',
      'retired_at' => Time.current.iso8601,
      'retired_reason' => "phone_number transferred to inbox #{channel.inbox&.id}"
    ).except('qr_code', 'pairing_code', 'jid', 'instance_id', 'connected', 'logged_in')

    # rubocop:disable Rails/SkipsModelValidations
    old_channel.update_columns(
      phone_number: nil,
      provider_config: old_provider_config,
      updated_at: Time.current
    )
    # rubocop:enable Rails/SkipsModelValidations
  end

  def assign_phone_to_current_channel!(phone_number)
    new_provider_config = channel.provider_config.to_h.deep_stringify_keys.except('phone_conflict')

    # rubocop:disable Rails/SkipsModelValidations
    channel.update_columns(
      phone_number: phone_number,
      provider_config: new_provider_config,
      updated_at: Time.current
    )
    # rubocop:enable Rails/SkipsModelValidations
    channel.provider_config = new_provider_config
    channel.phone_number = phone_number
  end
end
