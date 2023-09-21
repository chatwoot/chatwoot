class SentimentColumnToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :sentiment, :jsonb, default: {}
  end
end
