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
