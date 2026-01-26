class AllowNullInboxIdInLeadFollowUpSequences < ActiveRecord::Migration[7.0]
  def change
    change_column_null :lead_follow_up_sequences, :inbox_id, true
  end
end
