class UpdateIndexesForContacts < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    add_searchable_index
    remove_old_index
    add_activity_index
  end

  def down
    remove_index :contacts, name: 'index_contacts_searchable_fields_gin', if_exists: true
    remove_index :contacts, name: 'index_resolved_contacts_on_account_and_last_activity', if_exists: true

    add_index :contacts,
              [:account_id, :last_activity_at],
              order: { last_activity_at: 'DESC NULLS LAST' },
              algorithm: :concurrently,
              name: 'index_contacts_on_account_id_and_last_activity_at'
  end

  private

  def add_searchable_index
    execute "SET statement_timeout = '3600000';"
    execute 'DROP INDEX IF EXISTS index_contacts_searchable_fields_gin;'
    execute <<-SQL.squish
      CREATE INDEX CONCURRENTLY index_contacts_searchable_fields_gin
      ON contacts USING gin (
        name gin_trgm_ops,
        email gin_trgm_ops,
        phone_number gin_trgm_ops,
        identifier gin_trgm_ops,
        (additional_attributes->>'company_name') gin_trgm_ops
      )
      WHERE (email <> '' OR phone_number <> '' OR identifier <> '');
    SQL
  end

  def remove_old_index
    remove_index :contacts, name: 'index_contacts_on_account_id_and_last_activity_at', if_exists: true
  end

  def add_activity_index
    add_index :contacts,
              [:account_id, :last_activity_at],
              name: 'index_resolved_contacts_on_account_and_last_activity',
              where: "(email <> '' OR phone_number <> '' OR identifier <> '')",
              order: { last_activity_at: 'DESC NULLS LAST' },
              algorithm: :concurrently
  end
end
