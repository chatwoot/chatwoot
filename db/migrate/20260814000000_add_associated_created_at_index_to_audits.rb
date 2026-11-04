class AddAssociatedCreatedAtIndexToAudits < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    # Serves account-scoped audit log lists filtered and sorted by created_at,
    # which otherwise sort every audit row matched by the associated index.
    add_index :audits, [:associated_type, :associated_id, :created_at],
              name: 'index_audits_on_associated_and_created_at',
              algorithm: :concurrently,
              if_not_exists: true
  end
end
