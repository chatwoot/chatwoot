class AddPineconeApiKeyToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :pinecone_api_key, :string
  end
end
