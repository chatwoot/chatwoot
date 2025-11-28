class OttivNotification < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :primary_actor, polymorphic: true
  belongs_to :secondary_actor, polymorphic: true, optional: true

  NOTIFICATION_TYPES = {
    conversation_creation: 1,
    conversation_assignment: 2,
    assigned_conversation_new_message: 3,
    conversation_mention: 4,
    participating_conversation_new_message: 5,
    sla_missed_first_response: 6,
    sla_missed_next_response: 7,
    sla_missed_resolution: 8
  }.freeze

  enum notification_type: NOTIFICATION_TYPES

  before_create :set_last_activity_at

  private

  def set_last_activity_at
    self.last_activity_at = Time.current
  end
end
