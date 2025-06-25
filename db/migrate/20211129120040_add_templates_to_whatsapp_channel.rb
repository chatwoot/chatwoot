class AddTemplatesToWhatsappChannel < ActiveRecord::Migration[6.1]
  def up
    change_table :channel_whatsapp, bulk: true do |t|
      t.column :message_templates, :jsonb, default: {}
      t.column :message_templates_last_updated, :datetime
    end
  end

  def down
    change_table :channel_whatsapp, bulk: true do |t|
      t.remove :message_templates
      t.remove :message_templates_last_updated
    end
  end
end
