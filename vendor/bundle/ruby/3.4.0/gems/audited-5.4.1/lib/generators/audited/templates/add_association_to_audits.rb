# frozen_string_literal: true

class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    add_column :audits, :association_id, :integer
    add_column :audits, :association_type, :string
  end

  def self.down
    remove_column :audits, :association_type
    remove_column :audits, :association_id
  end
end
