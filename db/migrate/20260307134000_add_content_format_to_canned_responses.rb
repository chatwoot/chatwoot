class AddContentFormatToCannedResponses < ActiveRecord::Migration[7.1]
  def change
    add_column :canned_responses, :content_format, :string, null: false, default: 'markdown'
  end
end
