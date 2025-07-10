class AddAvatarNameToChannelWebWidgets < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_web_widgets, :avatar_name, :string
  end
end
