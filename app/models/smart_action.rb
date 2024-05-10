# == Schema Information
#
# Table name: smart_actions
#
#  id                :bigint           not null, primary key
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

  def event_data
    {
      id: id,
      name: name,
      label: label,
      event: event,
      content: content,
      intent_type: intent_type,
      message_id: message_id,
      conversation_id: conversation_id,
      created_at: created_at
    }
  end
end
