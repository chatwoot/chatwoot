require 'rails_helper'

RSpec.describe Channels::Facebook::RedactContactDataJob do
  let(:facebook_id) { '1234567890' }
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:redis_key) { format(Redis::Alfred::META_DELETE_PROCESSING, id: facebook_id) }

  describe '#perform' do
    context 'when contact with facebook_id exists' do
      let(:contact) { create(:contact, :with_email, name: 'John Doe') }
      let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: facebook_id) }

      before do
        allow(Redis::Alfred).to receive(:delete)
        # Create the contact_inbox before running the test to ensure it exists
        # this is to get around the fact that `let!` is not permitted by our rubocop rules
        contact_inbox
      end

      it 'anonymizes contact data and removes processing flag' do
        described_class.perform_now(facebook_id)
        contact.reload

        expect(contact.name).to eq('Deleted User')
        expect(contact.email).to be_nil
        expect(contact.phone_number).to be_nil
        expect(contact.identifier).to be_nil
        expect(contact.additional_attributes).to eq({})
        expect(contact.custom_attributes).to eq({})

        expect(Redis::Alfred).to have_received(:delete).with(redis_key)
      end
    end

    context 'when contact with facebook_id does not exist' do
      before do
        allow(Redis::Alfred).to receive(:delete)
      end

      it 'still removes the processing flag from Redis' do
        described_class.perform_now(facebook_id)

        expect(Redis::Alfred).to have_received(:delete).with(redis_key)
      end
    end
  end
end
