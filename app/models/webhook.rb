# == Schema Information
#
# Table name: webhooks
#
#  id           :bigint           not null, primary key
#  url          :string
#  webhook_type :integer          default("account")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer
#  inbox_id     :integer
#

class Webhook < ApplicationRecord
  belongs_to :account
  belongs_to :inbox, optional: true

  validates :account_id, presence: true
  validates :url, uniqueness: { scope: [:account_id] }, format: { with: URI::DEFAULT_PARSER.make_regexp }

  enum webhook_type: { account: 0, inbox: 1 }
end
