class RemoveCarrierWaveAttributes < ActiveRecord::Migration[6.0]
  def change
    remove_column :contacts, :avatar, :string
    remove_column :channel_facebook_pages, :avatar, :string
    remove_column :attachments, :file, :string
  end
end
