class CreateChannelTelnyxSms < ActiveRecord::Migration[7.1]
  def up
    create_table :channel_telnyx_sms do |t|
      t.string :phone_number, null: false
      t.integer :account_id, null: false
      t.timestamps
    end

    add_index :channel_telnyx_sms, :phone_number, unique: true

    create_table :telnyx_sms_configs do |t|
      t.references :channel_telnyx_sms, null: false, foreign_key: true, index: { unique: true }
      t.string :api_key, null: false
      t.string :messaging_profile_id, null: false
      t.timestamps
    end

    migrate_telnyx_channels
    reset_pk_sequence!(:channel_telnyx_sms)
  end

  def down
    migrate_telnyx_channels_back
    reset_pk_sequence!(:channel_sms)
    drop_table :telnyx_sms_configs if table_exists?(:telnyx_sms_configs)
    drop_table :channel_telnyx_sms
  end

  private

  def migrate_telnyx_channels
    copy_telnyx_channels
    copy_telnyx_configs
    update_telnyx_inboxes('Channel::TelnyxSms')
    execute "DELETE FROM channel_sms WHERE provider = 'telnyx'"
  end

  def copy_telnyx_channels
    execute <<~SQL.squish
      INSERT INTO channel_telnyx_sms (id, phone_number, account_id, created_at, updated_at)
      SELECT id, phone_number, account_id, created_at, updated_at
      FROM channel_sms
      WHERE provider = 'telnyx'
    SQL
  end

  def copy_telnyx_configs
    execute <<~SQL.squish
      INSERT INTO telnyx_sms_configs (
        channel_telnyx_sms_id, api_key, messaging_profile_id, created_at, updated_at
      )
      SELECT
        id,
        provider_config->>'api_key',
        provider_config->>'messaging_profile_id',
        created_at,
        updated_at
      FROM channel_sms
      WHERE provider = 'telnyx'
    SQL
  end

  def update_telnyx_inboxes(channel_type)
    execute <<~SQL.squish
      UPDATE inboxes
      SET channel_type = '#{channel_type}'
      WHERE channel_type IN ('Channel::Sms', 'Channel::TelnyxSms')
        AND channel_id IN (
          SELECT id FROM channel_sms WHERE provider = 'telnyx'
          UNION
          SELECT id FROM channel_telnyx_sms
        )
    SQL
  end

  def migrate_telnyx_channels_back
    return migrate_legacy_telnyx_channels_back unless table_exists?(:telnyx_sms_configs)

    copy_telnyx_channels_back
    update_telnyx_inboxes('Channel::Sms')
  end

  def copy_telnyx_channels_back
    execute <<~SQL.squish
      INSERT INTO channel_sms (id, phone_number, provider, provider_config, account_id, created_at, updated_at)
      SELECT
        channel_telnyx_sms.id,
        channel_telnyx_sms.phone_number,
        'telnyx',
        jsonb_build_object(
          'api_key', telnyx_sms_configs.api_key,
          'messaging_profile_id', telnyx_sms_configs.messaging_profile_id
        ),
        channel_telnyx_sms.account_id,
        channel_telnyx_sms.created_at,
        channel_telnyx_sms.updated_at
      FROM channel_telnyx_sms
      INNER JOIN telnyx_sms_configs
        ON telnyx_sms_configs.channel_telnyx_sms_id = channel_telnyx_sms.id
    SQL
  end

  def migrate_legacy_telnyx_channels_back
    execute <<~SQL.squish
      INSERT INTO channel_sms (id, phone_number, provider, provider_config, account_id, created_at, updated_at)
      SELECT id, phone_number, 'telnyx', provider_config, account_id, created_at, updated_at
      FROM channel_telnyx_sms
    SQL

    update_telnyx_inboxes('Channel::Sms')
  end

  def reset_pk_sequence!(table)
    execute <<~SQL.squish
      SELECT setval(
        pg_get_serial_sequence('#{table}', 'id'),
        COALESCE((SELECT MAX(id) FROM #{table}), 1),
        EXISTS (SELECT 1 FROM #{table})
      )
    SQL
  end
end
