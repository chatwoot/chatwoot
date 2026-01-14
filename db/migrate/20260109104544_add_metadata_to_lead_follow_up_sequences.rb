class AddMetadataToLeadFollowUpSequences < ActiveRecord::Migration[7.0]
  def change
    add_column :lead_follow_up_sequences, :metadata, :jsonb, default: {}
  end
end
