class AddVipManagerPriorityGroup < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL.squish
      INSERT INTO priority_groups (name, account_id, created_at, updated_at)
      VALUES ('VIP Manager', 1, NOW(), NOW());
    SQL
  end

  def down
    execute <<-SQL.squish
      DELETE FROM priority_groups WHERE name = 'VIP Manager' AND account_id = 1;
    SQL
  end
end
