# == Schema Information
#
# Table name: audits
#
#  id              :bigint           not null, primary key
#  action          :string
#  associated_type :string
#  auditable_type  :string
#  audited_changes :jsonb
#  comment         :string
#  remote_address  :string
#  request_uuid    :string
#  user_type       :string
#  username        :string
#  version         :integer          default(0)
#  created_at      :datetime
#  associated_id   :bigint
#  auditable_id    :bigint
#  user_id         :bigint
#
# Indexes
#
#  associated_index              (associated_type,associated_id)
#  auditable_index               (auditable_type,auditable_id,version)
#  index_audits_on_created_at    (created_at)
#  index_audits_on_request_uuid  (request_uuid)
#  user_index                    (user_id,user_type)
#
class Enterprise::AuditLog < Audited::Audit
  after_save :log_additional_information
  after_create_commit :enqueue_ip_lookup, if: -> { remote_address.present? }

  def location
    [city, country].compact_blank.join(', ').presence
  end

  def masked_remote_address
    return if remote_address.blank?

    ip = IPAddr.new(remote_address)
    if ip.ipv4?
      "#{ip.to_s.split('.')[0..2].join('.')}.x"
    else
      "#{ip.to_string.split(':')[0..3].join(':')}::"
    end
  rescue IPAddr::Error
    nil
  end

  def resolve_ip_location!
    return if remote_address.blank?

    result = IpLookupService.new.perform(remote_address)
    return unless result

    update_columns(city: result.city, country: result.country, country_code: result.country_code) # rubocop:disable Rails/SkipsModelValidations
  end

  scope :with_auditable_types, ->(types) { where(auditable_type: types) }
  scope :created_after, ->(time) { where(created_at: time..) }
  scope :created_before, ->(time) { where(created_at: ..time) }
  scope :search_by_user, lambda { |query|
    term = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
    joins("LEFT JOIN users ON users.id = audits.user_id AND audits.user_type = 'User'")
      .where('audits.username ILIKE :term OR users.name ILIKE :term OR users.email ILIKE :term', term: term)
  }

  private

  def enqueue_ip_lookup
    Enterprise::AuditLogIpLookupJob.perform_later(self)
  end

  def log_additional_information
    # rubocop:disable Rails/SkipsModelValidations
    if auditable_type == 'Account' && auditable_id.present?
      update_columns(associated_type: auditable_type, associated_id: auditable_id, username: user&.email)
    else
      update_columns(username: user&.email)
    end
    # rubocop:enable Rails/SkipsModelValidations
  end
end
