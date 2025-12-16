class AddPineconeIndexToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :pinecone_index, :string
  end
end
