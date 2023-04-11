class AddContentAttributesToChannel < ActiveRecord::Migration[6.1]
  def up
    add_column :channel_facebook_pages, :content_attributes, :jsonb, default: {}
  end

  def down
    remove_column :channel_facebook_pages, :content_attributes, :jsonb
  end
end
