class CreateWidgetBubbleSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :widget_bubble_settings do |t|
      t.references :channel_web_widget, null: false, foreign_key: true
      t.string :position, default: 'right'
      t.string :bubble_type, default: 'standard'
      t.string :launcher_title, default: 'Chat with us'
      t.timestamps
    end
  end
end 