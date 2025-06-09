require 'rails_helper'

describe EmailChannelFinder do
  include ActionMailbox::TestHelper
  let!(:channel_email) { create(:channel_email) }

  describe '#perform' do
    context 'with cc mail' do
      let(:reply_cc_mail) { create_inbound_email_from_fixture('reply_cc.eml') }

      it 'return channel with cc email' do
        channel_email.update!(email: 'test@example.com')
        channel = described_class.new(reply_cc_mail.mail).perform
        expect(channel).to eq(channel_email)
      end
    end

    context 'with to mail' do
      let(:reply_mail) { create_inbound_email_from_fixture('reply.eml') }

      it 'return channel with to email' do
        channel_email.update!(email: 'test@example.com')
        reply_mail.mail['to'] = 'test@example.com'
        channel = described_class.new(reply_mail.mail).perform
        expect(channel).to eq(channel_email)
      end

      it 'return channel with to+extension email' do
        channel_email.update!(email: 'test@example.com')
        reply_mail.mail['to'] = 'test+123@example.com'
        channel = described_class.new(reply_mail.mail).perform
        expect(channel).to eq(channel_email)
      end

      it 'return channel with cc email' do
        channel_email.update!(email: 'test@example.com')
        reply_mail.mail['to'] = nil
        reply_mail.mail['cc'] = 'test@example.com'
        channel = described_class.new(reply_mail.mail).perform
        expect(channel).to eq(channel_email)
      end

      it 'return channel with bcc email' do
        channel_email.update!(email: 'test@example.com')
        reply_mail.mail['to'] = nil
        reply_mail.mail['bcc'] = 'test@example.com'
        channel = described_class.new(reply_mail.mail).perform
        expect(channel).to eq(channel_email)
      end

      it 'return channel with X-Original-To email' do
        channel_email.update!(email: 'test@example.com')
        reply_mail.mail['to'] = nil
        reply_mail.mail['X-Original-To'] = 'test@example.com'
        channel = described_class.new(reply_mail.mail).perform
        expect(channel).to eq(channel_email)
      end
    end
  end
end
