class BackPopulatesConversation < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_web_widgets, :back_populates_conversation, :boolean, default: true, null: false
  end
end
