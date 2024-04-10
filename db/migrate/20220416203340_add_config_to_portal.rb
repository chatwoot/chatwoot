class AddConfigToPortal < ActiveRecord::Migration[6.1]
  def change
    add_column :kbase_portals, :config, :jsonb, default: { allowed_locales: ['en'] }
  end
end
