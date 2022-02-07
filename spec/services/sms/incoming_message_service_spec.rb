require 'rails_helper'

describe Sms::IncomingMessageService do
  describe '#perform' do
    let!(:sms_channel) { create(:channel_sms) }

    context 'when valid text message params' do
      it 'creates appropriate conversations, message and contacts' do
        params =  {

          'id': '3232420-2323-234324',
          'owner': sms_channel.phone_number,
          'applicationId': '2342349-324234d-32432432',
          'time': '2022-02-02T23:14:05.262Z',
          'segmentCount': 1,
          'direction': 'in',
          'to': [
            sms_channel.phone_number
          ],
          'from': '+14234234234',
          'text': 'test message'

        }.with_indifferent_access
        described_class.new(inbox: sms_channel.inbox, params: params).perform
        expect(sms_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('+1 423-423-4234')
        expect(sms_channel.inbox.messages.first.content).to eq('test message')
      end
    end
  end
end
