class AddIndexForSearchOperations < ActiveRecord::Migration[6.1]
  def change
    enable_extension('pg_trgm')
    add_index(:messages, [:account_id, :inbox_id])
    add_index(:messages, :content, using: 'gin', opclass: :gin_trgm_ops)
    add_index(:contacts, [:name, :email, :phone_number, :identifier],
              using: 'gin', opclass: :gin_trgm_ops, name: 'index_contacts_on_name_email_phone_number_identifier')
  end
end
