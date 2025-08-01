# == Schema Information
#
# Table name: customers
#
#  id                  :integer          not null, primary key
#  name                :string(255)      not null
#  chatwoot_account_id :integer
#  agent_api_url       :string(512)
#  agent_api_key       :string(512)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

module Dashassist
  class Customer < ApplicationRecord
    self.table_name = 'customers'
    
    establish_connection(
      adapter: 'postgresql',
      encoding: 'unicode',
      pool: 5,
      host: ENV.fetch('POSTGRES_HOST', 'localhost'),
      port: ENV.fetch('POSTGRES_PORT', '5432').to_i,
      database: 'omni_purchase_db',
      username: ENV.fetch('POSTGRES_USERNAME', 'postgres'),
      password: ENV.fetch('POSTGRES_PASSWORD', ''),
      sslmode: 'require'
    )

    validates :name, presence: true
    validates :chatwoot_account_id, presence: true, uniqueness: true

    belongs_to :account, foreign_key: 'chatwoot_account_id', class_name: 'Account', optional: true

    def self.find_by_chatwoot_account(account_id)
      find_by(chatwoot_account_id: account_id)
    end
  end
end 