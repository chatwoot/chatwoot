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

  scope :ask_copilot, -> { where(event: 'ask_copilot') }
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
      conversation_id: conversation.display_id,
      created_at: created_at
    }
  end

  private

  def execute_after_create_commit_callbacks
    dispatch_create_events
  end

  def dispatch_create_events
    return unless active?

    Rails.configuration.dispatcher.dispatch(SMART_ACTION_CREATED, Time.zone.now, smart_action: self, performed_by: Current.executed_by)
  end
end
