# frozen_string_literal: true

class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    rename_column :audits, :changes, :audited_changes
  end

  def self.down
    rename_column :audits, :audited_changes, :changes
  end
end
