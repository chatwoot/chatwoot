# frozen_string_literal: true

# == Schema Information
#
# Table name: template_usage_logs
#
#  id                  :bigint           not null, primary key
#  channel_type        :string
#  parameters_used     :jsonb
#  sender_type         :string
#  success             :boolean          default(TRUE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  conversation_id     :bigint
#  message_template_id :bigint           not null
#  sender_id           :bigint
#
# Indexes
#
#  index_template_usage_logs_on_account_id                       (account_id)
#  index_template_usage_logs_on_account_id_and_created_at        (account_id,created_at)
#  index_template_usage_logs_on_channel_type                     (channel_type)
#  index_template_usage_logs_on_conversation_id                  (conversation_id)
#  index_template_usage_logs_on_created_at                       (created_at)
#  index_template_usage_logs_on_message_template_id              (message_template_id)
#  index_template_usage_logs_on_message_template_id_and_success  (message_template_id,success)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => cascade
#  fk_rails_...  (message_template_id => message_templates.id) ON DELETE => cascade
#

class TemplateUsageLog < ApplicationRecord
  # Constants
  SENDER_TYPES = %w[User AgentBot DialogflowBot ExternalBot].freeze
  CHANNEL_TYPES = %w[
    apple_messages_for_business
    whatsapp
    sms
    email
    web_widget
    website
    telegram
    line
    twitter
    facebook
  ].freeze

  # Associations
  belongs_to :message_template
  belongs_to :account
  belongs_to :conversation, optional: true

  # Validations
  validates :sender_type, inclusion: { in: SENDER_TYPES }, allow_nil: true
  validates :channel_type, inclusion: { in: CHANNEL_TYPES }, allow_nil: true

  validate :validate_parameters_used_format

  # Scopes
  scope :successful, -> { where(success: true) }
  scope :failed, -> { where(success: false) }
  scope :for_template, ->(template_id) { where(message_template_id: template_id) }
  scope :for_account, ->(account_id) { where(account_id: account_id) }
  scope :for_conversation, ->(conversation_id) { where(conversation_id: conversation_id) }
  scope :by_sender_type, ->(sender_type) { where(sender_type: sender_type) if sender_type.present? }
  scope :by_channel, ->(channel_type) { where(channel_type: channel_type) if channel_type.present? }
  scope :recent, -> { order(created_at: :desc) }
  scope :within_period, lambda { |start_time, end_time|
    where(created_at: start_time..end_time) if start_time.present? && end_time.present?
  }

  # Class Methods

  # Get usage statistics for a template
  def self.template_stats(template_id)
    logs = for_template(template_id)

    {
      total_uses: logs.count,
      successful_uses: logs.successful.count,
      failed_uses: logs.failed.count,
      success_rate: calculate_success_rate(logs),
      uses_by_channel: logs.group(:channel_type).count,
      uses_by_sender: logs.group(:sender_type).count,
      recent_uses: logs.recent.limit(10).pluck(:created_at, :channel_type, :success)
    }
  end

  # Get usage statistics for an account
  def self.account_stats(account_id, start_time = nil, end_time = nil)
    logs = for_account(account_id)
    logs = logs.within_period(start_time, end_time) if start_time && end_time

    {
      total_templates_used: logs.distinct.count(:message_template_id),
      total_uses: logs.count,
      successful_uses: logs.successful.count,
      failed_uses: logs.failed.count,
      success_rate: calculate_success_rate(logs),
      most_used_templates: logs.group(:message_template_id).count.sort_by { |_k, v| -v }.first(10),
      uses_by_channel: logs.group(:channel_type).count,
      uses_by_day: logs.group_by_day(:created_at).count
    }
  end

  # Get success rate percentage
  def self.calculate_success_rate(logs)
    total = logs.count
    return 0.0 if total.zero?

    successful = logs.successful.count
    ((successful.to_f / total) * 100).round(2)
  end

  # Group logs by day
  def self.group_by_day(column)
    group("DATE(#{column})")
  end

  # Get popular parameters for a template
  def self.popular_parameters(template_id)
    logs = for_template(template_id).where.not(parameters_used: {})

    parameter_counts, parameter_values = collect_parameter_stats(logs)

    {
      parameter_usage: parameter_counts,
      common_values: format_common_values(parameter_values)
    }
  end

  def self.collect_parameter_stats(logs)
    parameter_counts = Hash.new(0)
    parameter_values = Hash.new { |h, k| h[k] = Hash.new(0) }

    logs.find_each do |log|
      next if log.parameters_used.blank?

      log.parameters_used.each do |key, value|
        parameter_counts[key] += 1
        # Track value frequency (for string/simple types)
        parameter_values[key][value] += 1 if value.is_a?(String) || value.is_a?(Numeric)
      end
    end

    [parameter_counts, parameter_values]
  end

  def self.format_common_values(parameter_values)
    parameter_values.transform_values { |v| v.sort_by { |_k, count| -count }.first(5).to_h }
  end

  # Instance Methods

  # Check if the usage was successful
  def successful?
    success == true
  end

  # Check if the usage failed
  def failed?
    success == false
  end

  # Get a human-readable description of the usage
  def description
    parts = []
    parts << "Template '#{message_template.name}'" if message_template
    parts << "used in #{channel_type}" if channel_type.present?
    parts << "by #{sender_type}" if sender_type.present?
    parts << "in conversation ##{conversation_id}" if conversation_id.present?
    parts << "(#{success ? 'success' : 'failed'})"

    parts.join(' ')
  end

  # Get parameter summary
  def parameter_summary
    return {} if parameters_used.blank?

    parameters_used.transform_values do |value|
      case value
      when Array
        { type: 'array', length: value.length }
      when Hash
        { type: 'object', keys: value.keys }
      else
        { type: value.class.name.downcase, value: value }
      end
    end
  end

  private

  def validate_parameters_used_format
    return if parameters_used.blank?

    unless parameters_used.is_a?(Hash)
      errors.add(:parameters_used, 'must be a hash')
      return
    end

    # Ensure all keys are strings
    parameters_used.each_key do |key|
      unless key.is_a?(String) || key.is_a?(Symbol)
        errors.add(:parameters_used, 'keys must be strings or symbols')
        break
      end
    end
  end
end
