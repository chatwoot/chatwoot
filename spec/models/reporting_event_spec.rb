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
require 'rails_helper'

RSpec.describe ReportingEvent do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:value) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inbox).optional }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:conversation).optional }
  end
end
