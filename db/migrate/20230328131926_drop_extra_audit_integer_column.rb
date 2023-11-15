class DropExtraAuditIntegerColumn < ActiveRecord::Migration[6.1]
  def change
    # this column was added unintentionally for a time in a migration but not in schema.rb, so some
    # installations will have it and some won't.
    remove_column :audits, :integer, :integer, default: 0, if_exists: true
  end
end
