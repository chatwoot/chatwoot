class Removeinboxid < ActiveRecord::Migration[5.0]
  def change
    remove_column :facebook_pages, :inbox_id
  end
end
