class AddTranscriptToWhatsappCalls < ActiveRecord::Migration[7.1]
  def change
    add_column :whatsapp_calls, :transcript, :text
  end
end
