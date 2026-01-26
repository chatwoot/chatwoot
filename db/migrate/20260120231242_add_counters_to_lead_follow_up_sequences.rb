class AddCountersToLeadFollowUpSequences < ActiveRecord::Migration[7.1]
  def change
    change_table :lead_follow_up_sequences do |t|
      t.integer :enrollments_count, default: 0
      t.integer :active_enrollments_count, default: 0
      t.integer :completed_enrollments_count, default: 0
      t.integer :cancelled_enrollments_count, default: 0
      t.integer :failed_enrollments_count, default: 0
    end
  end
end
