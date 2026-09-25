# Delete migration and spec after 2 consecutive releases.
class Migration::AddSearchIndexesJob < ApplicationJob
  queue_as :within_10_minutes

  def perform
    ActiveRecord::Migration[6.1].add_index(:messages, [:account_id, :inbox_id], algorithm: :concurrently)
    ActiveRecord::Migration[6.1].add_index(:messages, :content, using: 'gin', opclass: :gin_trgm_ops, algorithm: :concurrently)
    ActiveRecord::Migration[6.1].add_index(
      :contacts,
      [:name, :email, :phone_number, :identifier],
      using: 'gin',
      opclass: :gin_trgm_ops,
      name: 'index_contacts_on_name_email_phone_number_identifier',
      algorithm: :concurrently
    )
  end
end
