require 'rails_helper'

describe Xmpp::ProcessMessageService do
  let(:account) { create(:account) }
  let(:xmpp_channel) { create(:channel_xmpp, account: account) }
  let(:xmpp_inbox) { create(:inbox, channel: xmpp_channel, account: account) }

  let(:service) { described_class.new(xmpp_channel, message) }

  context 'with basic message' do
    let(:message) do
      Blather::Stanza::Message.new.tap do |m|
        m.from = 'test@example.com'
        m.body = 'hi'
        m << Niceogiri::XML::Node.new(:delay, m.document, 'urn:xmpp:delay').tap do |delay|
          delay['stamp'] = '2020-01-01T00:00:00Z'
        end
        m << Niceogiri::XML::Node.new(:'stanza-id', m.document, 'urn:xmpp:sid:0').tap do |sid|
          sid['by'] = xmpp_channel.jid
          sid['id'] = 'a_mam_id'
        end
      end
    end

    describe '#perform' do
      it 'saves message' do
        service.perform
        message = Message.find_by(source_id: 'a_mam_id')
        expect(message.sender.name).to eq 'test'
        expect(message.content).to eq 'hi'
        expect(message.created_at).to eq Time.parse('2020-01-01T00:00:00Z')
      end

      it 'prevents duplicate' do
        service.perform
        service.perform
        expect(Message.where(source_id: 'a_mam_id').count).to be 1
      end
    end
  end
end
