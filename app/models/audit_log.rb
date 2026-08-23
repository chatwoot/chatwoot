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
class AuditLog < ApplicationRecord
  self.table_name = 'audits'

  ACTIONS = %w[create update destroy].freeze

  belongs_to :auditable, polymorphic: true, optional: true
  belongs_to :associated, polymorphic: true, optional: true
  belongs_to :user, polymorphic: true, optional: true

  scope :with_action, ->(action) { where(action: action) }
  scope :with_auditable_type, ->(auditable_type) { where(auditable_type: auditable_type) }
  scope :with_user, ->(user_id) { where(user_id: user_id) }
  scope :created_after, ->(date) { where(created_at: date.beginning_of_day..) }
  scope :created_before, ->(date) { where(created_at: ..date.end_of_day) }

  def audited_record_label
    auditable_type || associated_type
  end

  def actor_label
    return username if username.present?
    return "User ##{user_id}" if user_id.present?

    'System'
  end

  def actor_email
    return nil unless user

    user.respond_to?(:email) ? user.email : nil
  end
end
