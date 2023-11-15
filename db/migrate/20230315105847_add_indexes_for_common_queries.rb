class AddIndexesForCommonQueries < ActiveRecord::Migration[6.1]
  # disabling ddl transaction is required for concurrent index creation
  # https://thoughtbot.com/blog/how-to-create-postgres-indexes-concurrently-in
  disable_ddl_transaction!

  def change
    ActiveRecord::Migration[6.1].add_index(:inboxes, [:channel_id, :channel_type], algorithm: :concurrently)
    ActiveRecord::Migration[6.1].add_index(:conversations, [:account_id, :inbox_id, :status, :assignee_id], name: 'conv_acid_inbid_stat_asgnid_idx',
                                                                                                            algorithm: :concurrently)
  end
end
