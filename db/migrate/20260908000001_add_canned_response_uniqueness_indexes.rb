class AddCannedResponseUniquenessIndexes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  PUBLIC_INDEX = 'index_canned_responses_on_account_and_short_code_public'.freeze
  PRIVATE_INDEX = 'index_canned_responses_on_account_creator_code_private'.freeze

  def up
    ensure_no_duplicate_canned_responses!

    add_index :canned_responses,
              [:account_id, :short_code],
              unique: true,
              where: 'visibility = 0',
              name: PUBLIC_INDEX,
              algorithm: :concurrently
    add_index :canned_responses,
              [:account_id, :created_by_id, :short_code],
              unique: true,
              where: 'visibility = 1 AND created_by_id IS NOT NULL',
              name: PRIVATE_INDEX,
              algorithm: :concurrently
  end

  def down
    remove_index :canned_responses, name: PRIVATE_INDEX, algorithm: :concurrently, if_exists: true
    remove_index :canned_responses, name: PUBLIC_INDEX, algorithm: :concurrently, if_exists: true
  end

  private

  def ensure_no_duplicate_canned_responses!
    public_duplicates = select_values <<~SQL.squish
      SELECT CONCAT(visibility, '/', account_id, '/', short_code)
      FROM canned_responses
      WHERE visibility = 0
      GROUP BY visibility, account_id, short_code
      HAVING COUNT(*) > 1
    SQL

    private_duplicates = select_values <<~SQL.squish
      SELECT CONCAT(visibility, '/', account_id, '/', created_by_id, '/', short_code)
      FROM canned_responses
      WHERE visibility = 1 AND created_by_id IS NOT NULL
      GROUP BY visibility, account_id, created_by_id, short_code
      HAVING COUNT(*) > 1
    SQL

    duplicates = public_duplicates + private_duplicates
    return if duplicates.empty?

    raise ActiveRecord::MigrationError,
          "Duplicate canned responses must be resolved before migrating: #{duplicates.join(', ')}"
  end
end
