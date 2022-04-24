# == Schema Information
#
# Table name: webhooks
#
#  id            :bigint           not null, primary key
#  subscriptions :jsonb
#  url           :string
#  webhook_type  :integer          default("account")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer
#  inbox_id      :integer
#
# Indexes
#
#  index_webhooks_on_account_id_and_url  (account_id,url) UNIQUE
#

class Webhook < ApplicationRecord
  belongs_to :account
  belongs_to :inbox, optional: true

  validates :account_id, presence: true
  validates :url, uniqueness: { scope: [:account_id] }, format: URI::DEFAULT_PARSER.make_regexp(%w[http https])
  before_save :ensure_webhook_subscriptions

  enum webhook_type: { account: 0, inbox: 1 }

  private

  def ensure_webhook_subscriptions
    invalid_subscriptions = !subscriptions.instance_of?(Array) || subscriptions.blank?
    errors.add(:subscriptions, 'Subscriptions should not be empty') if invalid_subscriptions
  end
end
