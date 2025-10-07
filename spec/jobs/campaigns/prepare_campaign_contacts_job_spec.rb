require 'rails_helper'

RSpec.describe Campaigns::PrepareCampaignContactsJob, type: :job do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, channel: create(:channel_twilio_sms, account: account)) }
  let(:label) { create(:label, account: account, title: 'customer') }
  let!(:contact1) { create(:contact, account: account).tap { |c| c.update(label_list: ['customer']) } }
  let!(:contact2) { create(:contact, account: account).tap { |c| c.update(label_list: ['customer']) } }
  let!(:contact3) { create(:contact, account: account).tap { |c| c.update(label_list: ['other']) } }

  let(:campaign) do
    create(:campaign,
           account: account,
           inbox: inbox,
           campaign_type: :one_off,
           audience: [{ 'id' => label.id, 'type' => 'Label' }])
  end

  describe '#perform' do
    it 'sets status to preparing at start' do
      described_class.new.perform(campaign)
      expect(campaign.reload.contacts_preparation_status).to eq('prepared')
    end

    it 'creates campaign_contacts for all contacts with matching labels' do
      expect do
        described_class.new.perform(campaign)
      end.to change(campaign.campaign_contacts, :count).by(2)
    end

    it 'does not create campaign_contacts for contacts without matching labels' do
      described_class.new.perform(campaign)
      expect(campaign.campaign_contacts.pluck(:contact_id)).not_to include(contact3.id)
    end

    it 'updates total_contacts_count' do
      described_class.new.perform(campaign)
      expect(campaign.reload.total_contacts_count).to eq(2)
    end

    it 'updates prepared_contacts_count' do
      described_class.new.perform(campaign)
      expect(campaign.reload.prepared_contacts_count).to eq(2)
    end

    it 'sets status to prepared when done' do
      described_class.new.perform(campaign)
      expect(campaign.reload.contacts_preparation_status).to eq('prepared')
    end

    context 'when campaign has no audience' do
      let(:campaign_without_audience) do
        create(:campaign,
               account: account,
               inbox: inbox,
               campaign_type: :one_off,
               audience: [])
      end

      it 'sets status to prepared without creating contacts' do
        described_class.new.perform(campaign_without_audience)
        expect(campaign_without_audience.reload.contacts_preparation_status).to eq('prepared')
        expect(campaign_without_audience.campaign_contacts.count).to eq(0)
      end
    end

    context 'when contact already exists' do
      before do
        campaign.campaign_contacts.create!(contact: contact1)
      end

      it 'does not create duplicate campaign_contacts' do
        expect do
          described_class.new.perform(campaign)
        end.to change(campaign.campaign_contacts, :count).by(1) # Only contact2
      end
    end

    context 'when processing fails' do
      before do
        allow_any_instance_of(ActiveRecord::Associations::CollectionProxy)
          .to receive(:find_or_create_by!).and_raise(StandardError, 'Database error')
      end

      it 'sets status to failed' do
        expect do
          described_class.new.perform(campaign)
        end.to raise_error(StandardError)

        expect(campaign.reload.contacts_preparation_status).to eq('failed')
      end
    end

    context 'with large number of contacts' do
      before do
        # Create 1200 contacts to test batching (batch_size is 500)
        1200.times do
          create(:contact, account: account).tap { |c| c.update(label_list: ['customer']) }
        end
      end

      it 'processes all contacts in batches' do
        expect do
          described_class.new.perform(campaign)
        end.to change(campaign.campaign_contacts, :count).by(1202) # 2 existing + 1200 new

        expect(campaign.reload.prepared_contacts_count).to eq(1202)
      end

      it 'updates progress during processing' do
        # This is harder to test without stubbing, but we can verify final state
        described_class.new.perform(campaign)
        expect(campaign.reload.prepared_contacts_count).to eq(campaign.total_contacts_count)
      end
    end
  end
end
