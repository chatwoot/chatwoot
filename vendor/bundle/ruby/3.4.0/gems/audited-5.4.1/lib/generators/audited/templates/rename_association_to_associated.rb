# frozen_string_literal: true

class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    if index_exists? :audits, [:association_id, :association_type], :name => 'association_index'
      remove_index :audits, :name => 'association_index'
    end

    rename_column :audits, :association_id, :associated_id
    rename_column :audits, :association_type, :associated_type

    add_index :audits, [:associated_id, :associated_type], :name => 'associated_index'
  end

  def self.down
    if index_exists? :audits, [:associated_id, :associated_type], :name => 'associated_index'
      remove_index :audits, :name => 'associated_index'
    end

    rename_column :audits, :associated_type, :association_type
    rename_column :audits, :associated_id, :association_id

    add_index :audits, [:association_id, :association_type], :name => 'association_index'
  end
end
