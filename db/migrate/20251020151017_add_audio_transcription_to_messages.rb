class AddAudioTranscriptionToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :transcription, :text
  end
end
