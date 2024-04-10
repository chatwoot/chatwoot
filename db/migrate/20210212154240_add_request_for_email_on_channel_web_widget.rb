class AddRequestForEmailOnChannelWebWidget < ActiveRecord::Migration[6.0]
  def up
    change_table :channel_web_widgets, bulk: true do |t|
      t.column :pre_chat_form_enabled, :boolean, default: false
      t.column :pre_chat_form_options, :jsonb, default: {}
    end
  end

  def down
    change_table :channel_web_widgets, bulk: true do |t|
      t.remove :pre_chat_form_enabled
      t.remove :pre_chat_form_options
    end
  end
end
