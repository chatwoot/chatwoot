class AddFaqsToChannelWebWidgets < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_web_widgets, :faqs, :jsonb, default: {}, null: false
  end
end
