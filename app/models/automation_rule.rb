# == Schema Information
#
# Table name: automation_rules
#
#  id                         :bigint           not null, primary key
#  actions                    :jsonb            not null
#  active                     :boolean          default(TRUE), not null
#  conditions                 :jsonb            not null
#  description                :text
#  event_name                 :string           not null
#  execution_delay            :integer
#  execution_delay_trigger    :string
#  monitor_event_activated_at :datetime
#  name                       :string           not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  account_id                 :bigint           not null
#  monitor_id                 :bigint
#
# Indexes
#
#  index_automation_rules_on_account_id  (account_id)
#  index_automation_rules_on_monitor_id  (monitor_id)
#
class AutomationRule < ApplicationRecord
  include Rails.application.routes.url_helpers
  include Reauthorizable

  MAX_SCHEDULED_MESSAGE_DELAY_MINUTES = 999 * 24 * 60 # 999 days
  EXECUTION_DELAY_RANGE = (10..43_200) # minutes: 10 min to 30 days
  # Conversation-level delayed rules key their episode on status; only status and attributes
  # that never change after the delay (inbox) are safe to also filter on.
  DELAYED_CONVERSATION_ATTRIBUTES = %w[status inbox_id].freeze
  # A conversation-level wait that is not about a status. `inactivity` measures the time since
  # anything at all happened on the conversation, so its episode is anchored on activity rather
  # than on status_changed_at. Nil keeps the status episode, which is what every older rule means.
  EXECUTION_DELAY_TRIGGERS = %w[inactivity].freeze

  belongs_to :account
  has_many :scheduled_messages, as: :author, dependent: :nullify
  has_many :pending_executions, class_name: 'AutomationRulePendingExecution', dependent: :delete_all
  has_many_attached :files

  validate :json_conditions_format
  validate :captain_conditions_feature
  validate :captain_conditions_operator
  validate :captain_conditions_description
  validate :json_actions_format
  validate :query_operator_presence
  validate :query_operator_value
  validate :scheduled_message_params
  validates :account_id, presence: true
  validates :execution_delay, numericality: { only_integer: true, in: EXECUTION_DELAY_RANGE }, allow_nil: true
  validates :execution_delay_trigger, inclusion: { in: EXECUTION_DELAY_TRIGGERS }, allow_nil: true
  validate :execution_delay_supported_conditions
  validate :execution_delay_supported_event
  validate :execution_delay_trigger_supported_event

  after_update_commit :reauthorized!, if: -> { saved_change_to_conditions? }
  # Discard rows armed under the old definition; they re-arm on the next matching event.
  after_update :discard_stale_pending_executions, if: :execution_config_changed?

  scope :active, -> { where(active: true) }

  def conditions_attributes
    %w[content email country_code status message_type browser_language assignee_id team_id referer city company_name inbox_id
       mail_subject phone_number priority conversation_language labels private_note sender_id sender_type captain_condition]
  end

  def actions_attributes
    %w[send_message add_label remove_label send_email_to_team assign_team assign_agent remove_assigned_agent
       remove_assigned_team send_webhook_event mute_conversation send_attachment change_status resolve_conversation
       open_conversation pending_conversation snooze_conversation change_priority send_email_transcript
       add_private_note create_scheduled_message remove_custom_attribute].freeze
  end

  # The wait is measured from the conversation's last activity instead of from a status change.
  def inactivity_trigger?
    execution_delay_trigger == 'inactivity'
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

  def captain_conditions(rule_conditions = conditions)
    rule_conditions.select { |obj| obj['attribute_key'] == Captain::AutomationConditionService::ATTRIBUTE_KEY }
  end

  def captain_judgments(rule_conditions)
    captain_conditions(rule_conditions).map { |obj| [obj['filter_operator'], obj['values']] }
  end

  # Only adding or changing a Captain condition needs the feature, so a rule saved before the
  # feature was revoked can still be deactivated, edited or cleaned up.
  def captain_conditions_feature
    return if account.feature_enabled?(Captain::AutomationConditionService::FEATURE)

    saved = new_record? ? {} : captain_judgments(conditions_was).tally
    return if captain_judgments(conditions).tally.all? { |judgment, count| count <= saved.fetch(judgment, 0) }

    errors.add(:conditions, 'Captain conditions require the Captain Classifier feature.')
  end

  def captain_conditions_operator
    return if captain_conditions.all? { |obj| Captain::AutomationConditionService::OPERATORS.include?(obj['filter_operator']) }

    errors.add(:conditions, 'Captain conditions support only the detects and does_not_detect operators.')
  end

  def captain_conditions_description
    values = captain_conditions.pluck('values')
    limit = Captain::AutomationConditionService::MAX_DESCRIPTION_LENGTH

    unless values.all? { |value| captain_description?(value) }
      return errors.add(:conditions, 'Captain conditions need exactly one description of what to detect.')
    end
    return if values.all? { |value| value.first.length <= limit }

    errors.add(:conditions, "Captain condition descriptions can have at most #{limit} characters.")
  end

  def captain_description?(value)
    value.is_a?(Array) && value.size == 1 && value.first.is_a?(String) && value.first.present?
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

  # The fire-time re-check cannot reconstruct changed_attributes, so delayed rules
  # cannot use attribute_changed conditions.
  def execution_delay_supported_conditions
    return if execution_delay.blank? || conditions.blank?
    return if conditions.none? { |obj| obj['filter_operator'] == 'attribute_changed' }

    errors.add(:execution_delay, 'cannot be used with attribute_changed conditions.')
  end

  def execution_delay_supported_event
    return if execution_delay.blank?
    # Refused outright, whatever the conditions say, and before the whitelist below can let it through on
    # an inbox or status filter. A delayed rule anchors its due time on `waiting_since` or on the message's
    # creation and dedupes its episode by message id; an edit has neither, so an edit of an hour-old
    # message would be overdue the moment it armed and a second edit of the same message could not arm at
    # all. Refused until the scheduling knows what an edit is (fazer-ai/chatwoot#648).
    return errors.add(:execution_delay, 'is not supported for rules triggered by an edit.') if event_name == 'message_edited'

    execution_delay_supported_conversation_conditions
  end

  # A status episode keys on status_changed_at alone, so a mutable attribute would collapse distinct
  # periods into one episode: only status and filters that never change after the delay (inbox) are
  # allowed. An inactivity episode is anchored on activity and re-anchored by it, and its conditions
  # are re-checked at fire time, so there the whole set is safe.
  def execution_delay_supported_conversation_conditions
    return if conditions.blank? || event_name == 'message_created' || inactivity_trigger?
    return if conditions.all? { |obj| DELAYED_CONVERSATION_ATTRIBUTES.include?(obj['attribute_key']) }

    errors.add(:execution_delay, 'only supports status and inbox conditions for conversation-level events.')
  end

  # The trigger describes how a wait is anchored, so it means nothing without a wait, and inactivity
  # is about the conversation rather than about a message.
  def execution_delay_trigger_supported_event
    return if execution_delay_trigger.blank?

    errors.add(:execution_delay_trigger, 'requires an execution delay.') if execution_delay.blank?
    errors.add(:execution_delay_trigger, 'is only supported for conversation_updated rules.') if event_name != 'conversation_updated'
  end

  # Deactivating counts: without it a rule turned off and back on before its due time would still
  # run the actions the admin turned it off to stop.
  def execution_config_changed?
    saved_change_to_active? || saved_change_to_execution_delay? || saved_change_to_event_name? ||
      saved_change_to_conditions? || saved_change_to_actions? || saved_change_to_execution_delay_trigger?
  end

  def discard_stale_pending_executions
    # armed = pending + processing, the rows the sweep would otherwise still run. Rows already
    # executing are left alone: their actions are in flight and cannot be called back.
    pending_executions.armed.delete_all
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
