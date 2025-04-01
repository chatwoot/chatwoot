class AddTranscriptionToAttachments < ActiveRecord::Migration[7.0]
  def change
    add_column :attachments, :transcription, :text
  end
end
