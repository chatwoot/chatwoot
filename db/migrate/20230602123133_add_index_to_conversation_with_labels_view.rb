class AddIndexToConversationWithLabelsView < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    # needs atleast one unuque index for concurrent refresh
    add_index :conversation_with_labels, :id, unique: true, algorithm: :concurrently
    add_index :conversation_with_labels, [:account_id, :status, :last_activity_at], algorithm: :concurrently,
                                                                                    name: 'idx_conv_labels_view__acc_id__status__last_activity'
    add_index :conversation_with_labels, :custom_attributes, using: :gin, algorithm: :concurrently
    add_index :conversation_with_labels, :labels_array, using: :gin, algorithm: :concurrently
    add_index :conversation_with_labels, :last_activity_at, order: { last_activity_at: :desc }, algorithm: :concurrently
  end
end
