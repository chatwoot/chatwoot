class Whatsapp::GroupConversationSchemaMigrationService
  MIGRATION_VERSION = '2026_04_structured_group_conversations'.freeze
  MIGRATION_VERSION_KEY = 'group_conversation_schema_migration_version'.freeze
  MIGRATION_COMPLETED_AT_KEY = 'group_conversation_schema_migrated_at'.freeze

  def self.migrated?(channel)
    channel.provider_config&.dig(MIGRATION_VERSION_KEY) == MIGRATION_VERSION
  end

  def self.mark_migrated!(channel)
    config = (channel.provider_config || {}).merge(
      'use_group_conversation_schema' => true,
      MIGRATION_VERSION_KEY => MIGRATION_VERSION,
      MIGRATION_COMPLETED_AT_KEY => Time.current.iso8601
    )

    # Skip validations to avoid provider credential checks while marking local migration metadata.
    channel.update_columns(provider_config: config, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end

  def initialize(batch_size: 100)
    @batch_size = batch_size
    @stats = { inboxes: 0, skipped: 0, conversations: 0, members: 0 }
  end

  def perform
    Channel::Whatsapp.where(provider: 'unoapi').includes(:inbox).find_each do |channel|
      migrate_channel(channel)
    end

    @stats
  end

  private

  def migrate_channel(channel)
    return skip_channel if channel.inbox.blank? || self.class.migrated?(channel)

    enable_structured_group_schema!(channel)
    stats = Whatsapp::GroupConversationBackfillService.new(batch_size: @batch_size, inbox: channel.inbox).perform
    self.class.mark_migrated!(channel.reload)

    @stats[:inboxes] += 1
    @stats[:conversations] += stats[:conversations]
    @stats[:members] += stats[:members]

    Rails.logger.info(
      "[WHATSAPP][GROUP] schema migration completed inbox_id=#{channel.inbox.id} conversations=#{stats[:conversations]} members=#{stats[:members]}"
    )
  end

  def skip_channel
    @stats[:skipped] += 1
  end

  def enable_structured_group_schema!(channel)
    config = (channel.provider_config || {}).merge('use_group_conversation_schema' => true)
    # Skip validations to avoid provider credential checks while enabling the local schema flag.
    channel.update_columns(provider_config: config, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end
end
