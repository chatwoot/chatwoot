# ref: https://dev.to/nodefiend/rails-migration-adding-a-unique-index-and-deleting-duplicates-5cde

class AddUniqueIndexOnInboxMembers < ActiveRecord::Migration[6.1]
  def up
    # partioning the duplicate records and then removing where more than one row is found
    ActiveRecord::Base.connection.execute('
      DELETE FROM inbox_members WHERE id IN (SELECT id from (
        SELECT id, user_id, inbox_id, ROW_NUMBER() OVER w AS rnum FROM inbox_members WINDOW w AS (
          PARTITION BY inbox_id, user_id ORDER BY id
        )
      ) t WHERE t.rnum > 1)
    ')
    add_index :inbox_members, [:inbox_id, :user_id], unique: true
  end

  def down
    remove_index :inbox_members, [:inbox_id, :user_id]
  end
end
