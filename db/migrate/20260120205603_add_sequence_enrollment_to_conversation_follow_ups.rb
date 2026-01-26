class AddSequenceEnrollmentToConversationFollowUps < ActiveRecord::Migration[7.1]
  def change
    add_reference :conversation_follow_ups, :sequence_enrollment, null: true, foreign_key: true
  end
end
