# == Schema Information
#
# Table name: automation_rules
#
#  id          :bigint           not null, primary key
#  actions     :jsonb            not null
#  active      :boolean          default(TRUE), not null
#  conditions  :jsonb            not null
#  description :text
#  event_name  :string           not null
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_automation_rules_on_account_id  (account_id)
#
class AutomationRule < ApplicationRecord
  include Rails.application.routes.url_helpers
  include Reauthorizable

  MAX_SCHEDULED_MESSAGE_DELAY_MINUTES = 999 * 24 * 60 # 999 days

  belongs_to :account
  has_many :scheduled_messages, as: :author, dependent: :nullify
  has_many_attached :files

  validate :json_conditions_format
  validate :json_actions_format
  validate :query_operator_presence
  validate :query_operator_value
  validate :scheduled_message_params
  validates :account_id, presence: true

  after_update_commit :reauthorized!, if: -> { saved_change_to_conditions? }

  scope :active, -> { where(active: true) }

  def conditions_attributes
    %w[content email country_code status message_type browser_language assignee_id team_id referer city company inbox_id
       mail_subject phone_number priority conversation_language labels]
  end

  def actions_attributes
    %w[send_message add_label remove_label send_email_to_team assign_team assign_agent send_webhook_event mute_conversation
       send_attachment change_status resolve_conversation open_conversation pending_conversation snooze_conversation change_priority
       send_email_transcript add_private_note create_scheduled_message].freeze
  end

  def file_base_data
    files.map do |file|
      {
        id: file.id,
        automation_rule_id: id,
        file_type: file.content_type,
        account_id: account_id,
        file_url: url_for(file),
        blob_id: file.blob_id,
        filename: file.filename.to_s
      }
    end
  end

  private

  def json_conditions_format
    return if conditions.blank?

    attributes = conditions.map { |obj, _| obj['attribute_key'] }
    conditions = attributes - conditions_attributes
    conditions -= account.custom_attribute_definitions.pluck(:attribute_key)
    errors.add(:conditions, "Automation conditions #{conditions.join(',')} not supported.") if conditions.any?
  end

  def json_actions_format
    return if actions.blank?

    attributes = actions.map { |obj, _| obj['action_name'] }
    actions = attributes - actions_attributes

    errors.add(:actions, "Automation actions #{actions.join(',')} not supported.") if actions.any?
  end

  def query_operator_presence
    return if conditions.blank?

    operators = conditions.select { |obj, _| obj['query_operator'].nil? }
    errors.add(:conditions, 'Automation conditions should have query operator.') if operators.length > 1
  end

  # This validation ensures logical operators are being used correctly in automation conditions.
  # And we don't push any unsanitized query operators to the database.
  def query_operator_value
    conditions.each do |obj|
      validate_single_condition(obj)
    end
  end

  def validate_single_condition(condition)
    query_operator = condition['query_operator']

    return if query_operator.nil?
    return if query_operator.empty?

    operator = query_operator.upcase
    errors.add(:conditions, 'Query operator must be either "AND" or "OR"') unless %w[AND OR].include?(operator)
  end

  def scheduled_message_params
    return if actions.blank?

    actions.each do |action|
      next unless action['action_name'] == 'create_scheduled_message'

      validate_scheduled_message_action(action)
    end
  end

  def validate_scheduled_message_action(action)
    params = action['action_params']&.first || {}
    delay_minutes = params['delay_minutes'].to_i

    unless delay_minutes.between?(1, MAX_SCHEDULED_MESSAGE_DELAY_MINUTES)
      errors.add(:actions, I18n.t('errors.automation.scheduled_message.delay_out_of_range'))
    end

    has_content = params['content'].present?
    has_attachment = params['blob_id'].present?
    has_template = params['template_params'].present?
    return if has_content || has_attachment || has_template

    errors.add(:actions, I18n.t('errors.automation.scheduled_message.content_attachment_or_template_required'))
  end
end

AutomationRule.include_mod_with('Audit::AutomationRule')
AutomationRule.prepend_mod_with('AutomationRule')
