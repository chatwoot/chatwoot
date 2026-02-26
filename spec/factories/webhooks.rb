# == Schema Information
#
# Table name: webhooks
#
#  id            :bigint           not null, primary key
#  name          :string
#  subscriptions :jsonb
#  url           :string
#  webhook_type  :integer          default("account_type")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer
#  inbox_id      :integer
#
# Indexes
#
#  index_webhooks_on_account_id_and_url  (account_id,url) UNIQUE
#
FactoryBot.define do
  factory :webhook do
    account_id { 1 }
    inbox_id { 1 }
    url { 'https://api.aloochat.ai' }
    name { 'My Webhook' }
    subscriptions do
      %w[
        conversation_status_changed
        conversation_updated
        conversation_created
        contact_created
        contact_updated
        message_created
        message_updated
        webwidget_triggered
      ]
    end
  end
end
