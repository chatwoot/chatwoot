# frozen_string_literal: true

class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    if index_exists?(:audits, [:auditable_type, :auditable_id], name: index_name)
      remove_index :audits, name: index_name
      add_index :audits, [:auditable_type, :auditable_id, :version], name: index_name
    end
  end

  def self.down
    if index_exists?(:audits, [:auditable_type, :auditable_id, :version], name: index_name)
      remove_index :audits, name: index_name
      add_index :audits, [:auditable_type, :auditable_id], name: index_name
    end
  end

  private

  def index_name
    'auditable_index'
  end
end
