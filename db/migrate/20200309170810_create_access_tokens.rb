class CreateAccessTokens < ActiveRecord::Migration[6.0]
  def change
    create_table :access_tokens do |t|
      t.references :owner, polymorphic: true, index: true
      t.string :token, index: { unique: true }
      t.timestamps
    end

    remove_column :agent_bots, :auth_token, :string

    [::User, ::AgentBot].each do |access_tokenable|
      generate_access_tokens(access_tokenable)
    end
  end

  def generate_access_tokens(access_tokenable)
    access_tokenable.find_in_batches do |record_batch|
      record_batch.each do |record|
        record.create_access_token if record.access_token.blank?
      end
    end
  end
end
