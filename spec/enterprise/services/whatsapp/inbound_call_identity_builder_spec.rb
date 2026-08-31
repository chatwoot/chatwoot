# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Whatsapp::InboundCallIdentityBuilder do
  let(:account) { create(:account) }
  let(:cloud_channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                              validate_provider_config: false, sync_templates: false)
  end
  let(:cloud_inbox) { cloud_channel.inbox }
  let(:params) { { contacts: [] } }

  describe '#perform' do
    context 'when the inbox addresses identifiers' do
      it 'leads with the phone when Meta still provides it' do
        identity = described_class.new(inbox: cloud_inbox, params: params)
                                  .perform({ from: '5541988887777', from_user_id: 'IN.2081978709342942' })

        expect(identity[:source_ids]).to eq(['5541988887777', 'IN.2081978709342942'])
      end

      it 'keeps identifiers behind the phone when all are present' do
        identity = described_class.new(inbox: cloud_inbox, params: params).perform(
          { from: '5541988887777', from_user_id: 'IN.2081978709342942', from_parent_user_id: 'IN.ENT.2081978709342942' }
        )

        expect(identity[:source_ids]).to eq(['5541988887777', 'IN.ENT.2081978709342942', 'IN.2081978709342942'])
      end

      it 'uses the parent identifier first when the phone is absent' do
        parent_only = described_class.new(inbox: cloud_inbox, params: params).perform(
          { from_user_id: 'IN.2081978709342942', from_parent_user_id: 'IN.ENT.2081978709342942' }
        )

        expect(parent_only[:source_ids]).to eq(['IN.ENT.2081978709342942', 'IN.2081978709342942'])
      end

      it 'keeps a BSUID-only conversation as the leading identity when the phone appears later' do
        contact = create(:contact, account: account)
        contact_inbox = create(:contact_inbox, contact: contact, inbox: cloud_inbox, source_id: 'IN.2081978709342942')
        create(:conversation, account: account, inbox: cloud_inbox, contact: contact, contact_inbox: contact_inbox)

        identity = described_class.new(inbox: cloud_inbox, params: params)
                                  .perform({ from: '5541988887777', from_user_id: 'IN.2081978709342942' })

        expect(identity[:source_ids]).to eq(['IN.2081978709342942', '5541988887777'])
      end

      it 'keeps the phone as the display name' do
        identity = described_class.new(inbox: cloud_inbox, params: params)
                                  .perform({ from: '5541988887777', from_user_id: 'IN.2081978709342942' })

        expect(identity[:contact_attributes][:name]).to eq('+5541988887777')
      end

      it 'names a caller without a phone by its identifier rather than leaving it blank' do
        identity = described_class.new(inbox: cloud_inbox, params: params)
                                  .perform({ from_user_id: 'IN.2081978709342942' })

        expect(identity[:contact_attributes][:name]).to eq('IN.2081978709342942')
      end

      it 'prefers the profile name over both' do
        named_params = { contacts: [{ wa_id: '5541988887777', profile: { name: 'Ada Lovelace' } }] }
        identity = described_class.new(inbox: cloud_inbox, params: named_params)
                                  .perform({ from: '5541988887777', from_user_id: 'IN.2081978709342942' })

        expect(identity[:contact_attributes][:name]).to eq('Ada Lovelace')
      end
    end

    context 'when the inbox cannot address identifiers' do
      let(:dialog_channel) do
        create(:channel_whatsapp, account: account, provider: 'default',
                                  validate_provider_config: false, sync_templates: false)
      end

      it 'keeps the phone first' do
        identity = described_class.new(inbox: dialog_channel.inbox, params: params)
                                  .perform({ from: '5541988887777', from_user_id: 'IN.2081978709342942' })

        expect(identity[:source_ids]).to eq(['5541988887777', 'IN.2081978709342942'])
      end
    end
  end
end
