require 'rails_helper'

RSpec.describe Contacts::ClassifyVisitorsService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  it 'makes a visitor in the audience of a campaign a lead instead of purging it' do
    contact = create(:contact, account: account, name: 'quiet-fog-31', created_at: 60.days.ago)
    campaign = create(:campaign, account: account, inbox: inbox)
    CampaignRecipient.create!(account: account, campaign: campaign, contact: contact, inbox: inbox)

    expect { described_class.new(from_id: contact.id, to_id: contact.id).perform }
      .to change { contact.reload.contact_type }.from('visitor').to('lead')
  end
end
