class AddSourceConfigToLeadFollowUpSequences < ActiveRecord::Migration[7.1]
  def change
    add_column :lead_follow_up_sequences, :source_type, :string, default: 'existing_conversations', null: false
    add_column :lead_follow_up_sequences, :source_config, :jsonb, null: false, default: {}
    add_column :lead_follow_up_sequences, :first_contact_config, :jsonb, null: false, default: {}
  end
end
