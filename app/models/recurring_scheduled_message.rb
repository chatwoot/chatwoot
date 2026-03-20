# == Schema Information
#
# Table name: recurring_scheduled_messages
#
#  id               :bigint           not null, primary key
#  author_type      :string           not null
#  content          :text
#  occurrences_sent :integer          default(0), not null
#  recurrence_rule  :jsonb            not null
#  status           :integer          default("draft"), not null
#  template_params  :jsonb
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  author_id        :bigint           not null
#  conversation_id  :bigint           not null
#  inbox_id         :bigint           not null
#
# Indexes
#
#  idx_recurring_sched_msgs_on_account_status             (account_id,status)
#  idx_recurring_sched_msgs_on_conversation_status        (conversation_id,status)
#  idx_recurring_sched_msgs_on_status                     (status)
#  index_recurring_scheduled_messages_on_account_id       (account_id)
#  index_recurring_scheduled_messages_on_author           (author_type,author_id)
#  index_recurring_scheduled_messages_on_conversation_id  (conversation_id)
#  index_recurring_scheduled_messages_on_inbox_id         (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
class RecurringScheduledMessage < ApplicationRecord
  include Rails.application.routes.url_helpers

  FREQUENCIES = %w[daily weekly monthly yearly].freeze
  END_TYPES = %w[never on_date after_count].freeze
  MONTHLY_TYPES = %w[day_of_month day_of_week].freeze

  belongs_to :account
  belongs_to :conversation
  belongs_to :inbox
  belongs_to :author, polymorphic: true

  has_many :scheduled_messages, dependent: :destroy
  has_one_attached :attachment

  enum status: { draft: 0, active: 1, completed: 2, cancelled: 3 }

  validates :author_type, inclusion: { in: ['User'] }
  validates :content, presence: true, unless: :content_optional?
  validate :validate_recurrence_rule

  scope :for_conversation, ->(conversation_id) { where(conversation_id: conversation_id) }

  def push_event_data
    base_event_data.tap do |data|
      data[:author] = author.push_event_data if author.present?
      data[:attachment] = attachment_data if attachment.attached?
      data[:pending_scheduled_message] = pending_scheduled_message_data
      data[:scheduled_messages] = recent_scheduled_messages_data
    end
  end

  def recurrence_description
    RecurringScheduledMessages::RecurrenceDescriptionService.new(recurrence_rule, locale: account&.locale || :en).generate
  end

  def attachment_data
    return unless attachment.attached?

    {
      id: attachment.id,
      recurring_scheduled_message_id: id,
      file_type: attachment.content_type,
      account_id: account_id,
      file_url: url_for(attachment),
      blob_id: attachment.blob.signed_id,
      filename: attachment.filename.to_s
    }
  end

  private

  def base_event_data
    {
      id: id, content: content, inbox_id: inbox_id,
      conversation_id: conversation.display_id, account_id: account_id,
      status: status, template_params: template_params,
      recurrence_rule: recurrence_rule, recurrence_description: recurrence_description,
      occurrences_sent: occurrences_sent, author_id: author_id, author_type: author_type,
      created_at: created_at.to_i, updated_at: updated_at.to_i
    }
  end

  def pending_scheduled_message_data
    sm = scheduled_messages.where(status: :pending).order(scheduled_at: :asc).first
    return unless sm

    { id: sm.id, scheduled_at: sm.scheduled_at&.to_i }
  end

  def recent_scheduled_messages_data
    scheduled_messages.order(scheduled_at: :desc).limit(50).map do |sm|
      { id: sm.id, status: sm.status, scheduled_at: sm.scheduled_at&.to_i, message_id: sm.message_id }
    end
  end

  def content_optional?
    template_params.present? || attachment.attached?
  end

  def validate_recurrence_rule
    if recurrence_rule.blank? || recurrence_rule == {}
      errors.add(:recurrence_rule, 'must have a valid frequency') if active?
      return
    end

    rule = recurrence_rule.with_indifferent_access
    validate_frequency(rule)
    validate_interval(rule)
    validate_weekly_fields(rule) if rule[:frequency] == 'weekly'
    validate_monthly_fields(rule) if rule[:frequency] == 'monthly'
    validate_end_type(rule)
  end

  def validate_frequency(rule)
    errors.add(:recurrence_rule, 'must have a valid frequency') unless rule[:frequency].in?(FREQUENCIES)
  end

  def validate_interval(rule)
    interval = rule[:interval]
    errors.add(:recurrence_rule, 'must have an interval >= 1') unless interval.is_a?(Integer) && interval >= 1
  end

  def validate_weekly_fields(rule)
    week_days = rule[:week_days]
    return errors.add(:recurrence_rule, 'must have week_days for weekly frequency') if week_days.blank? || !week_days.is_a?(Array)

    errors.add(:recurrence_rule, 'week_days must contain values between 0-6') unless week_days.all? { |d| d.is_a?(Integer) && d.between?(0, 6) }
  end

  def validate_monthly_fields(rule)
    errors.add(:recurrence_rule, 'must have a valid monthly_type') unless rule[:monthly_type].in?(MONTHLY_TYPES)
    return unless rule[:monthly_type] == 'day_of_week'

    errors.add(:recurrence_rule, 'must have monthly_week for day_of_week type') unless rule[:monthly_week].is_a?(Integer)
    errors.add(:recurrence_rule, 'must have monthly_weekday (0-6) for day_of_week type') unless rule[:monthly_weekday].is_a?(Integer) &&
                                                                                                rule[:monthly_weekday].between?(0, 6)
  end

  def validate_end_type(rule)
    end_type = rule[:end_type]
    errors.add(:recurrence_rule, 'must have a valid end_type') unless end_type.in?(END_TYPES)

    case end_type
    when 'on_date'
      validate_end_date(rule[:end_date])
    when 'after_count'
      end_count = rule[:end_count]
      errors.add(:recurrence_rule, 'must have end_count >= 1 for after_count end_type') unless end_count.is_a?(Integer) && end_count >= 1
    end
  end

  def validate_end_date(end_date)
    return errors.add(:recurrence_rule, 'must have an end_date for on_date end_type') if end_date.blank?

    Date.iso8601(end_date)
  rescue ArgumentError
    errors.add(:recurrence_rule, 'end_date must be a valid ISO8601 date (YYYY-MM-DD)')
  end
end
