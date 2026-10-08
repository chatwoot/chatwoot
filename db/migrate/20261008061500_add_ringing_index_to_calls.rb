class AddRingingIndexToCalls < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  # The ring timeout sweep looks for ringing calls older than a cutoff every 30 seconds;
  # almost every call is terminal, so the index covers only the ringing ones
  def change
    add_index :calls, [:provider, :created_at],
              where: "status = 'ringing'",
              name: 'index_calls_ringing_on_provider_and_created_at',
              algorithm: :concurrently
  end
end
