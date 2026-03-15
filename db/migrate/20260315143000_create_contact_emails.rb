class CreateContactEmails < ActiveRecord::Migration[7.1]
  def up
    audit_legacy_contact_emails!
    normalize_legacy_contact_emails!

    create_contact_emails_table!
    add_contact_emails_indexes!

    backfill_primary_contact_emails!
    validate_backfill!
  end

  def down
    drop_table :contact_emails
  end

  private

  def migration_contacts
    @migration_contacts ||= Class.new(ApplicationRecord) do
      self.table_name = 'contacts'
    end
  end

  def audit_legacy_contact_emails!
    invalid_rows, normalized_duplicates = collect_legacy_contact_email_issues
    duplicate_rows = normalized_duplicates.select { |_key, ids| ids.size > 1 }
    return if invalid_rows.empty? && duplicate_rows.empty?

    raise <<~MESSAGE
      Aborting contact email backfill. Resolve invalid or normalization-colliding contact emails before rerunning.
      Invalid contacts: #{invalid_rows.first(10)}
      Duplicate groups: #{duplicate_rows.first(10).to_h}
    MESSAGE
  end

  def collect_legacy_contact_email_issues
    invalid_rows = []
    normalized_duplicates = Hash.new { |hash, key| hash[key] = [] }

    migration_contacts.where.not(email: nil).find_each do |contact|
      normalized_email = normalize_contact_email(contact.email)
      if normalized_email.blank? || !valid_contact_email?(normalized_email)
        invalid_rows << { id: contact.id, email: contact.email }
        next
      end

      normalized_duplicates[[contact.account_id, normalized_email]] << contact.id
    end

    [invalid_rows, normalized_duplicates]
  end

  def normalize_legacy_contact_emails!
    migration_contacts
      .where.not(email: nil)
      .where.not('email = LOWER(BTRIM(email))')
      .update_all("email = LOWER(BTRIM(email))")
  end

  def backfill_primary_contact_emails!
    now = Time.current

    rows = migration_contacts.where.not(email: nil).pluck(:id, :account_id, :email).filter_map do |contact_id, account_id, email|
      normalized_email = normalize_contact_email(email)

      "(#{contact_id}, #{account_id}, #{connection.quote(normalized_email)}, TRUE, #{connection.quote(now)}, #{connection.quote(now)})"
    end

    return if rows.empty?

    execute(<<~SQL.squish)
      INSERT INTO contact_emails (contact_id, account_id, email, "primary", created_at, updated_at)
      VALUES #{rows.join(', ')}
    SQL
  end

  def validate_backfill!
    invalid_contact_ids = migration_contacts
                          .where.not(email: nil)
                          .where.not(id: connection.select_values(<<~SQL.squish))
                            SELECT contacts.id
                            FROM contacts
                            INNER JOIN contact_emails ON contact_emails.contact_id = contacts.id
                            WHERE contact_emails."primary" = TRUE
                              AND contacts.email = contact_emails.email
                            GROUP BY contacts.id
                            HAVING COUNT(contact_emails.id) = 1
                          SQL

    return unless invalid_contact_ids.exists?

    raise "Contact email backfill validation failed for contact IDs: #{invalid_contact_ids.limit(10).pluck(:id)}"
  end

  def normalize_contact_email(email)
    email.to_s.strip.downcase
  end

  def valid_contact_email?(email)
    email.match?(Devise.email_regexp)
  end

  def create_contact_emails_table!
    create_table :contact_emails do |t|
      t.integer :contact_id, null: false
      t.integer :account_id, null: false
      t.string :email, null: false
      t.boolean :primary, null: false, default: false
      t.timestamps
    end

    add_foreign_key :contact_emails, :contacts
    add_foreign_key :contact_emails, :accounts
  end

  def add_contact_emails_indexes!
    add_index :contact_emails, :contact_id
    add_index :contact_emails, [:account_id, :primary]
    add_index :contact_emails, 'lower(email), account_id',
              unique: true,
              name: 'index_contact_emails_on_lower_email_and_account_id'
    add_index :contact_emails, :contact_id,
              unique: true,
              where: '"primary" = TRUE',
              name: 'index_contact_emails_on_contact_id_where_primary'
  end
end
