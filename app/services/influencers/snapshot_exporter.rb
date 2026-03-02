require 'json'

class Influencers::SnapshotExporter
  CONTACT_ATTRIBUTES = %w[
    name
    identifier
    contact_type
    custom_attributes
    additional_attributes
    created_at
    updated_at
  ].freeze

  PROFILE_EXCLUDED_ATTRIBUTES = %w[id account_id contact_id lock_version].freeze

  def initialize(account:, output_path:)
    @account = account
    @output_path = Pathname(output_path)
  end

  def perform
    FileUtils.mkdir_p(output_path.dirname)
    File.write(output_path, JSON.pretty_generate(snapshot_payload))
    output_path
  end

  private

  attr_reader :account, :output_path

  def snapshot_payload
    {
      exported_at: serialize_value(Time.current),
      account: {
        id: account.id,
        name: account.name
      },
      profiles: account.influencer_profiles.includes(:contact).order(:id).map do |profile|
        {
          contact: serialize_record(profile.contact, CONTACT_ATTRIBUTES),
          profile: serialize_profile(profile)
        }
      end
    }
  end

  def serialize_profile(profile)
    serialize_record(profile, profile_attribute_names).merge(
      'status' => profile.status
    )
  end

  def profile_attribute_names
    @profile_attribute_names ||= InfluencerProfile.column_names - PROFILE_EXCLUDED_ATTRIBUTES
  end

  def serialize_record(record, attribute_names)
    record.attributes.slice(*attribute_names).transform_values do |value|
      serialize_value(value)
    end
  end

  def serialize_value(value)
    case value
    when ActiveSupport::TimeWithZone, Time, Date, DateTime
      value.iso8601
    else
      value
    end
  end
end
