class AddSenderCreatedIndexToMessages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  # Adds created_at to the (sender_type, sender_id) index so per-assistant
  # windowed lookups (Captain Overview stats) can range-scan the time slice
  # instead of reading every lifetime row and filtering at the heap. The new
  # index is a left-prefix superset of the old one.
  #
  # TODO: drop the now-redundant index_messages_on_sender_type_and_sender_id
  # once this index has been running in production long enough to confirm it
  # fully replaces the old one.
  def up
    add_index :messages, [:sender_type, :sender_id, :created_at],
              name: 'index_messages_on_sender_and_created', algorithm: :concurrently, if_not_exists: true
  end

  def down
    remove_index :messages, name: 'index_messages_on_sender_and_created',
                            algorithm: :concurrently, if_exists: true
  end
end
