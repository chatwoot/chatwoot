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
  store :custom_attributes, accessors: [:to, :from, :link, :content]

  belongs_to :conversation
  belongs_to :message

  validates :message_id, presence: true
  validates :conversation_id, presence: true

  CREATE_BOOKING = 'create_booking'.freeze
  CANCEL_BOOKING = 'cancel_booking'.freeze
  ASK_COPILOT = 'ask_copilot'.freeze
  AUTOMATED_RESPONSE = 'automated_response'.freeze

  MANUAL_ACTION = [
    CREATE_BOOKING,
    CANCEL_BOOKING
  ]

  scope :ask_copilot, -> { where(event: ASK_COPILOT) }
  scope :active, -> { where(active: true) }
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

  private

  def execute_after_create_commit_callbacks
    dispatch_create_events
    create_automated_response
  end

  def dispatch_create_events
    return unless active?

    Rails.configuration.dispatcher.dispatch(SMART_ACTION_CREATED, Time.zone.now, smart_action: self, performed_by: Current.executed_by)
  end

  def create_automated_response
    return unless event == AUTOMATED_RESPONSE

    Messages::MessageBuilder.new(conversation.assignee, conversation, { content: content }).perform
  end
end
