# == Schema Information
#
# Table name: agent_bot_access_tokens
#
#  id         :integer          not null, primary key
#  account_id :bigint           not null
#  inbox_id   :bigint
#  token      :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  idx_agent_bot_access_tokens_account_id  (account_id)
#  idx_agent_bot_access_tokens_inbox_id    (inbox_id)
#  idx_agent_bot_access_tokens_token       (token) UNIQUE
#

module Dashassist
  class AgentBotAccessToken < ApplicationRecord
    self.table_name = 'agent_bot_access_tokens'

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

    validates :account_id, presence: true
    validates :token, presence: true, uniqueness: true

    belongs_to :account, class_name: 'Account', foreign_key: 'account_id'
    belongs_to :inbox, class_name: 'Inbox', foreign_key: 'inbox_id', optional: true

    def self.find_by_token(token)
      find_by(token: token)
    end

    def self.find_by_account(account_id)
      where(account_id: account_id)
    end

    def self.find_by_inbox(inbox_id)
      where(inbox_id: inbox_id)
    end
  end
end 