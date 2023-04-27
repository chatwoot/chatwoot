class AddMessageSourceIdentifierToMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :messages, :message_source_identifier, :string, default: nil, null: true
  end
end
