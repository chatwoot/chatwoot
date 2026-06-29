class AddDocumentNumberToContacts < ActiveRecord::Migration[7.0]
  def change
    add_column :contacts, :document_number, :string
    add_index :contacts, [:account_id, :document_number], unique: true, where: "document_number <> ''"

    # Extend the existing GIN search index to include document_number.
    # gin_trgm_ops is required for GIN indexes on text/varchar columns.
    remove_index :contacts, name: :index_contacts_on_name_email_phone_number_identifier
    add_index :contacts,
              [:name, :email, :phone_number, :identifier, :document_number],
              name: :index_contacts_on_name_email_phone_identifier_document,
              using: :gin,
              opclass: :gin_trgm_ops
  end
end
