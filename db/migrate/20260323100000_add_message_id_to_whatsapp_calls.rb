class AddMessageIdToWhatsappCalls < ActiveRecord::Migration[7.1]
  def change
    add_reference :whatsapp_calls, :message, null: true, foreign_key: true, index: true
  end
end
