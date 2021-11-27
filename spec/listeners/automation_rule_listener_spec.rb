require 'rails_helper'
describe CampaignListener do
  let(:listener) { described_class.instance }
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account, identifier: '123') }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) { create(:conversation, contact_inbox: contact_inbox, inbox: inbox) }
  let(:automation_rule) { create(:automation_rule_staus_changes, account: account) }

  let!(:event) do
    Events::Base.new('conversation_status_changed', Time.zone.now,
                     contact_inbox: contact_inbox, event_info: { campaign_id: campaign.display_id })
  end

  describe '#conversation_status_changed' do
    let(:builder) { double }

    before do
      allow(::AutomationRules::ConditionsFilterService).to receive(:new).and_return(builder)
      allow(builder).to receive(:perform)
    end

    context 'when rule matches' do
      it 'triggers automation rule' do
        expect(Campaigns::CampaignConversationBuilder).to receive(:new)
          .with({ contact_inbox_id: contact_inbox.id, campaign_display_id: campaign.display_id, conversation_additional_attributes: {} }).once
        listener.campaign_triggered(event)
      end
    end
  end
end
