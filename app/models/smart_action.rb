# == Schema Information
#
# Table name: smart_actions
#
#  id                :bigint           not null, primary key
#  active            :boolean          default(TRUE)
#  custom_attributes :jsonb
#  description       :string
#  event             :string
#  intent_type       :string
#  label             :string
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  conversation_id   :bigint           not null
#  message_id        :bigint           not null
#
# Indexes
#
#  index_smart_actions_on_conversation_id  (conversation_id)
#  index_smart_actions_on_message_id       (message_id)
#
class SmartAction < ApplicationRecord
  store :custom_attributes, accessors: [:to, :from, :link, :content, :criteria, :score, :sentiment]

  belongs_to :conversation
  belongs_to :message

  validates :message_id, presence: true
  validates :conversation_id, presence: true

  SMART_ACTION_BOT_NAME = 'Anna'.freeze

  CREATE_BOOKING = 'create_booking'.freeze
  CANCEL_BOOKING = 'cancel_booking'.freeze
  ASK_COPILOT = 'ask_copilot'.freeze
  AUTOMATED_RESPONSE = 'automated_response'.freeze
  RESOLVE_CONVERSATION = 'resolve_conversation'.freeze
  CREATE_PRIVATE_MESSAGE = 'create_private_message'.freeze
  HANDOVER_CONVERSATION = 'handover_conversation'.freeze
  RECORD_OUTGOING_MESSAGE_SCORE = 'record_message_score'.freeze
  RECORD_INCOMING_MESSAGE_SENTIMENT = 'record_message_sentiment'.freeze
  ESCALATE_CONVERSATION = 'escalate_conversation'.freeze

  MANUAL_ACTION = [
    CREATE_BOOKING,
    CANCEL_BOOKING
  ].freeze

  scope :ask_copilot, -> { where(event: ASK_COPILOT) }
  scope :outgoing_message_score, -> { where(event: RECORD_OUTGOING_MESSAGE_SCORE) }
  scope :incoming_message_sentiment, -> { where(event: RECORD_INCOMING_MESSAGE_SENTIMENT) }
  scope :escalate_conversation, -> { where(event: ESCALATE_CONVERSATION) }
  scope :resolve_conversation, -> { where(event: RESOLVE_CONVERSATION) }
  scope :create_private_message, -> { where(event: CREATE_PRIVATE_MESSAGE) }
  scope :automated_response, -> { where(event: AUTOMATED_RESPONSE) }
  scope :handover_conversation, -> { where(event: HANDOVER_CONVERSATION) }
  scope :active, -> { where(active: true) }
  scope :filter_by_created_at, ->(range) { where(created_at: range) if range.present? }

  delegate :account, to: :conversation

  after_create_commit :execute_after_create_commit_callbacks

  def event_data
    {
      id: id,
      name: name,
      label: label,
      event: event,
      content: content,
      intent_type: intent_type,
      message_id: message_id,
      manual_action: manual_action?,
      conversation_id: conversation.display_id,
      created_at: created_at
    }
  end

  def manual_action?
    MANUAL_ACTION.include?(event)
  end

  def bot_agent
    find_or_create_bot_agent
  end

  private

  def execute_after_create_commit_callbacks
    dispatch_create_events

    set_agent_bot
    trigger_after_create_callbacks
    restore_current_user
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def trigger_after_create_callbacks
    case event
    when AUTOMATED_RESPONSE
      create_automated_response
    when CREATE_PRIVATE_MESSAGE
      create_private_message
    when ESCALATE_CONVERSATION
      create_escalate_conversation
    when HANDOVER_CONVERSATION
      handover_conversation_to_team
    when RECORD_OUTGOING_MESSAGE_SCORE
      record_outgoing_message_score
    when RECORD_INCOMING_MESSAGE_SENTIMENT
      record_incoming_message_sentiment
    when RESOLVE_CONVERSATION
      resolve_conversation
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def set_agent_bot
    @prev_user = Current.user
    Current.user = bot_agent
  end

  def restore_current_user
    Current.user = @prev_user
  end

  def dispatch_create_events
    return unless active?

    Rails.configuration.dispatcher.dispatch(SMART_ACTION_CREATED, Time.zone.now, smart_action: self, performed_by: Current.executed_by)
  end

  def create_automated_response
    return unless event == AUTOMATED_RESPONSE

    Messages::MessageBuilder.new(assignee, conversation, { content: content }).perform
  end

  def create_private_message
    return unless event == CREATE_PRIVATE_MESSAGE

    Messages::MessageBuilder.new(assignee, conversation, { content: content, private: true }).perform
  end

  def create_escalate_conversation
    return unless event == ESCALATE_CONVERSATION

    conversation.team_id = handover_team&.id
    conversation.save!
  end

  def handover_conversation_to_team
    return unless event == HANDOVER_CONVERSATION

    conversation.team_id = handover_team&.id
    conversation.save!
  end

  def resolve_conversation
    return unless event == RESOLVE_CONVERSATION

    conversation.status = :resolved
    conversation.save!
  end

  def record_incoming_message_sentiment
    return unless event == RECORD_INCOMING_MESSAGE_SENTIMENT

    update_cached_message
  end

  def record_outgoing_message_score
    return unless event == RECORD_OUTGOING_MESSAGE_SCORE

    update_cached_message
  end

  def handover_team
    conversation.account.teams.where(high_priority: true).first
  end

  def update_cached_message
    Rails.configuration.dispatcher.dispatch(MESSAGE_UPDATED, Time.zone.now, message: self.message)
  end

  def find_or_create_bot_agent
    agent = conversation.account.agent_bots.digitaltolk.find_or_initialize_by(name: SMART_ACTION_BOT_NAME)

    if agent.new_record?
      agent.save!

      begin
        file_path = Rails.root.join('public', 'dashboard', 'images', 'agent-bots', 'bot_anna.png')
        agent.avatar.attach(io: File.open(file_path), filename: 'avatar.png', content_type: 'image/png')
      rescue StandardError => e
        Rails.logger.error "Error while attaching avatar to bot: #{e.message}"
      end
    end

    agent
  end

  def assignee
    conversation_handled_by_bot? ? bot_agent : conversation.assignee
  end

  def conversation_handled_by_bot?
    conversation.handled_by != 'human_agent'
  end
end
