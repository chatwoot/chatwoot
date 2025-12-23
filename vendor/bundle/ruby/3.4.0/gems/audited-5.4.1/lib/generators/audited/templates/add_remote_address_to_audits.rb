# frozen_string_literal: true

class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    add_column :audits, :remote_address, :string
  end

  def self.down
    remove_column :audits, :remote_address
  end
end

