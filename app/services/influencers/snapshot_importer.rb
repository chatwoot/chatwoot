require 'json'

class Influencers::SnapshotImporter
  CONTACT_ATTRIBUTES = %w[
    name
    identifier
    contact_type
    custom_attributes
    additional_attributes
  ].freeze
  CONTACT_TIMESTAMP_ATTRIBUTES = %w[created_at updated_at].freeze

  PROFILE_EXCLUDED_ATTRIBUTES = %w[
    id
    account_id
    contact_id
    lock_version
    created_at
    updated_at
  ].freeze
  PROFILE_TIMESTAMP_ATTRIBUTES = %w[
    created_at
    updated_at
    last_post_at
    report_fetched_at
    last_synced_at
  ].freeze

  def initialize(account:, snapshot_path:)
    @account = account
    @snapshot_path = Pathname(snapshot_path)
  end

  def perform
    snapshot.fetch('profiles', []).count do |entry|
      import_entry(entry)
      true
    end
  end

  private

  attr_reader :account, :snapshot_path

  def snapshot
    @snapshot ||= JSON.parse(File.read(snapshot_path))
  end

  def import_entry(entry)
    profile_data = entry.fetch('profile')
    contact = upsert_contact(entry.fetch('contact'), fallback_identifier: "ig:#{profile_data.fetch('username')}")
    upsert_profile(contact, profile_data)
  end

  def upsert_contact(contact_data, fallback_identifier:)
    identifier = contact_data['identifier'].presence || fallback_identifier
    contact = account.contacts.find_or_initialize_by(identifier: identifier)

    contact.assign_attributes(
      build_contact_attributes(contact_data).merge(
        identifier: identifier
      )
    )
    contact.save!
    sync_timestamps(contact, contact_data, CONTACT_TIMESTAMP_ATTRIBUTES)
    contact
  end

  def upsert_profile(contact, profile_data)
    profile = contact.influencer_profile || account.influencer_profiles.find_or_initialize_by(
      username: profile_data.fetch('username'),
      platform: profile_data.fetch('platform', 'instagram')
    )

    profile.account = account
    profile.contact = contact
    profile.assign_attributes(build_profile_attributes(profile_data))
    profile.save!
    sync_timestamps(profile, profile_data, PROFILE_TIMESTAMP_ATTRIBUTES)
    profile
  end

  def build_contact_attributes(contact_data)
    contact_data.slice(*CONTACT_ATTRIBUTES)
  end

  def build_profile_attributes(profile_data)
    profile_data.slice(*profile_attribute_names).merge(
      'status' => profile_data['status'],
      'last_post_at' => parse_time(profile_data['last_post_at']),
      'report_fetched_at' => parse_time(profile_data['report_fetched_at']),
      'last_synced_at' => parse_time(profile_data['last_synced_at'])
    ).compact
  end

  def profile_attribute_names
    @profile_attribute_names ||= InfluencerProfile.column_names - PROFILE_EXCLUDED_ATTRIBUTES
  end

  def sync_timestamps(record, attributes, timestamp_keys)
    timestamp_values = timestamp_keys.index_with do |key|
      parse_time(attributes[key])
    end.compact
    return if timestamp_values.blank?

    record.update_columns(timestamp_values) # rubocop:disable Rails/SkipsModelValidations
  end

  def parse_time(value)
    return if value.blank?

    Time.zone.parse(value)
  end
end
