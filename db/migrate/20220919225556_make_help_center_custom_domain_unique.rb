class MakeHelpCenterCustomDomainUnique < ActiveRecord::Migration[6.1]
  def change
    add_index :portals, :custom_domain, unique: true
  end
end
