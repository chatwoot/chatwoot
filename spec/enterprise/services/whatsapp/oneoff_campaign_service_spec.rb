require 'rails_helper'

RSpec.describe Whatsapp::OneoffCampaignService do
  let(:account) { create(:account) }
  let!(:whatsapp_channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let!(:whatsapp_inbox) { whatsapp_channel.inbox }
  let(:label) { create(:label, account: account) }
  let!(:campaign) do
    create(:campaign, inbox: whatsapp_inbox, account: account,
                      audience: [{ type: 'Label', id: label.id }],
                      template_params: {
                        'name' => 'ticket_status_updated',
                        'namespace' => '23423423_2342423_324234234_2343224',
                        'category' => 'UTILITY',
                        'language' => 'en',
                        'processed_params' => { 'body' => { 'name' => 'John' } }
                      })
  end

  before do
    account.enable_features!(:whatsapp_campaign)
    allow_any_instance_of(described_class).to receive(:channel).and_return(whatsapp_channel) # rubocop:disable RSpec/AnyInstance
    allow(whatsapp_channel).to receive(:send_template).and_return('wamid.sent')
  end

  def contact_in_audience(phone_number: nil)
    contact = create(:contact, account: account, phone_number: phone_number)
    contact.update_labels([label.title])
    contact
  end

  it 'addresses a recipient that only has a business scoped user id' do
    contact = contact_in_audience
    create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'BR.5aBcD1')

    expect(whatsapp_channel).to receive(:send_template).with('BR.5aBcD1', anything, nil).and_return('wamid.sent')

    described_class.new(campaign: campaign).perform

    expect(campaign.campaign_recipients.find_by(contact: contact)).to be_sent
  end

  it 'keeps addressing by phone number when the recipient has both' do
    contact = contact_in_audience(phone_number: '+555199999999')
    create(:contact_inbox, contact: contact, inbox: whatsapp_inbox, source_id: 'BR.5aBcD1')

    expect(whatsapp_channel).to receive(:send_template).with('+555199999999', anything, nil).and_return('wamid.sent')

    described_class.new(campaign: campaign).perform
  end

  it 'skips a recipient that has neither, and records why' do
    contact = contact_in_audience

    expect(whatsapp_channel).not_to receive(:send_template)

    described_class.new(campaign: campaign).perform

    expect(campaign.campaign_recipients.find_by(contact: contact)).to have_attributes(
      status: 'skipped',
      error_message: 'Phone number and business scoped user id are missing'
    )
  end
end
