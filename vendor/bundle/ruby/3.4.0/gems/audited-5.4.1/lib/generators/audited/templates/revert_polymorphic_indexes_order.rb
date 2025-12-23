# frozen_string_literal: true

class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    fix_index_order_for [:associated_id, :associated_type], 'associated_index'
    fix_index_order_for [:auditable_id, :auditable_type], 'auditable_index'
  end

  def self.down
    fix_index_order_for [:associated_type, :associated_id], 'associated_index'
    fix_index_order_for [:auditable_type, :auditable_id], 'auditable_index'
  end

  private

  def fix_index_order_for(columns, index_name)
    if index_exists? :audits, columns, name: index_name
      remove_index :audits, name: index_name
      add_index :audits, columns.reverse, name: index_name
    end
  end
end
