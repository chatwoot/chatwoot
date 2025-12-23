ActiveRecord::Schema.define do
  create_table :audits, force: true do |t|
    t.column :auditable_id, :integer
    t.column :auditable_type, :string
    t.column :user_id, :integer
    t.column :user_type, :string
    t.column :username, :string
    t.column :action, :string
    t.column :audited_changes, :text
    t.column :version, :integer, default: 0
    t.column :comment, :string
    t.column :created_at, :datetime
    t.column :remote_address, :string
    t.column :associated_id, :integer
    t.column :associated_type, :string
  end

  add_index :audits, [:auditable_type, :auditable_id], name: "auditable_index"
end
