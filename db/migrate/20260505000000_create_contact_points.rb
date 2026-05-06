class CreateContactPoints < ActiveRecord::Migration[7.0]
  def change
    create_contact_email_table
    create_contact_phone_table
    add_contact_email_indexes
    add_contact_phone_indexes
  end

  private

  def create_contact_email_table
    create_table :contact_emails do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :contact, null: false, foreign_key: { on_delete: :cascade }
      t.string :email, null: false
      t.timestamps
    end
  end

  def create_contact_phone_table
    create_table :contact_phones do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :contact, null: false, foreign_key: { on_delete: :cascade }
      t.string :phone_number, null: false
      t.timestamps
    end
  end

  def add_contact_email_indexes
    add_index :contact_emails, 'lower((email)::text), account_id',
              unique: true,
              name: 'index_contact_emails_on_lower_email_and_account_id'
    add_index :contact_emails, :email,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: 'index_contact_emails_on_email_trigram'
  end

  def add_contact_phone_indexes
    add_index :contact_phones, [:account_id, :phone_number],
              unique: true,
              name: 'index_contact_phones_on_account_id_and_phone_number'
    add_index :contact_phones, :phone_number,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: 'index_contact_phones_on_phone_number_trigram'
  end
end
