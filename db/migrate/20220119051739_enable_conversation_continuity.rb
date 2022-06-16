class EnableConversationContinuity < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_web_widgets, :continuity_via_email, :boolean, null: false, default: true
  end
end
