require 'rails_helper'

RSpec.describe BillingHelper do
  describe '#conversations_this_month' do
    let(:user) { create(:user) }
    let(:account) { create(:account, custom_attributes: { 'plan_name' => 'Hacker' }) }

    before do
      create(:installation_config, {
               name: 'CHATWOOT_CLOUD_PLANS',
               value: [
                 {
                   'name' => 'Hacker',
                   'product_id' => ['plan_id'],
                   'price_ids' => ['price_1']
                 },
                 {
                   'name' => 'Startups',
                   'product_id' => ['plan_id_2'],
                   'price_ids' => ['price_2']
                 }
               ]
             })
    end

    it 'counts only the conversations created this month' do
      create_list(:conversation, 5, account: account, created_at: Time.zone.today - 1.day)
      create_list(:conversation, 3, account: account, created_at: 2.months.ago)
      expect(helper.send(:conversations_this_month, account)).to eq(5)
    end

    it 'counts only non web widget channels' do
      create(:inbox, account: account, channel_type: Channel::WebWidget)
      expect(account.inboxes.count).to eq(1)
      expect(helper.send(:non_web_inboxes, account)).to eq(0)

      create(:inbox, account: account, channel_type: Channel::Api)
      expect(account.inboxes.count).to eq(2)
      expect(helper.send(:non_web_inboxes, account)).to eq(1)
    end

    it 'returns true for the default plan name' do
      expect(helper.send(:default_plan?, account)).to be(true)
      account.custom_attributes['plan_name'] = 'Startups'
      expect(helper.send(:default_plan?, account)).to be(false)
    end
  end
end
