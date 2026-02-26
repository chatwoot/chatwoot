# == Schema Information
#
# Table name: reporting_events
#
#  id                      :bigint           not null, primary key
#  event_end_time          :datetime
#  event_start_time        :datetime
#  name                    :string
#  value                   :float
#  value_in_business_hours :float
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :integer
#  conversation_id         :integer
#  inbox_id                :integer
#  user_id                 :integer
#
# Indexes
#
#  index_reporting_events_on_account_id            (account_id)
#  index_reporting_events_on_conversation_id       (conversation_id)
#  index_reporting_events_on_created_at            (created_at)
#  index_reporting_events_on_inbox_id              (inbox_id)
#  index_reporting_events_on_name                  (name)
#  index_reporting_events_on_user_id               (user_id)
#  reporting_events__account_id__name__created_at  (account_id,name,created_at)
#
FactoryBot.define do
  factory :reporting_event do
    name { 'first_response' }
    value { 1.5 }
    value_in_business_hours { 1 }
    account
    inbox { association :inbox, account: account }
    user { association :user, account: account }
    conversation { association :conversation, account: account, inbox: inbox }
    event_start_time { 2.hours.ago }
    event_end_time { 1.hour.ago }
  end
end
