class AddPasswordDigestToPortals < ActiveRecord::Migration[7.1]
  def change
    add_column :portals, :password_digest, :string
  end
end
