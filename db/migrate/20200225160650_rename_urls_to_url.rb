class RenameUrlsToUrl < ActiveRecord::Migration[6.0]
  def change
    rename_column :webhooks, :urls, :url
  end
end