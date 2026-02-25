require 'rails_helper'

describe EmailChannelFinder do
  include ActionMailbox::TestHelper

  let!(:channel_email) { create(:channel_email) }

  describe '#perform' do
    context 'with cc mail' do
      let(:reply_cc_mail) { create_inbound_email_from_fixture('reply_cc.eml') }

      it 'return channel with cc email' do
        channel_email.update(email: 'test@example.com')
        channel = described_class.new(reply_cc_mail.mail).perform
        expect(channel).to eq(channel_email)
      end
    end

    context 'with to mail' do
      let(:reply_mail) { create_inbound_email_from_fixture('reply.eml') }

      it 'return channel with to email' do
        channel_email.update(email: 'test@example.com')
        reply_mail.mail['to'] = 'test@example.com'
        channel = described_class.new(reply_mail.mail).perform
        expect(channel).to eq(channel_email)
      end

      it 'return channel with to+extension email' do
        channel_email.update(email: 'test@example.com')
        reply_mail.mail['to'] = 'test+123@example.com'
        channel = described_class.new(reply_mail.mail).perform
        expect(channel).to eq(channel_email)
      end

      it 'return channel with cc email' do
        channel_email.update(email: 'test@example.com')
        reply_mail.mail['to'] = nil
        reply_mail.mail['cc'] = 'test@example.com'
        channel = described_class.new(reply_mail.mail).perform
        expect(channel).to eq(channel_email)
      end

      it 'return channel with bcc email' do
        channel_email.update(email: 'test@example.com')
        reply_mail.mail['to'] = nil
        reply_mail.mail['bcc'] = 'test@example.com'
        channel = described_class.new(reply_mail.mail).perform
        expect(channel).to eq(channel_email)
      end

      it 'skip bcc email when account is configured to skip BCC processing' do
        channel_email.update(email: 'test@example.com')
        reply_mail.mail['to'] = nil
        reply_mail.mail['bcc'] = 'test@example.com'

        allow(GlobalConfigService).to receive(:load)
          .with('SKIP_INCOMING_BCC_PROCESSING', '')
          .and_return(channel_email.account_id.to_s)

        channel = described_class.new(reply_mail.mail).perform
        expect(channel).to be_nil
      end

      it 'skip bcc email when account is in multiple account ids config' do
        channel_email.update(email: 'test@example.com')
        reply_mail.mail['to'] = nil
        reply_mail.mail['bcc'] = 'test@example.com'

        # Include this account along with other account IDs
        other_account_ids = [123, 456, channel_email.account_id, 789]
        allow(GlobalConfigService).to receive(:load)
          .with('SKIP_INCOMING_BCC_PROCESSING', '')
          .and_return(other_account_ids.join(','))

        channel = described_class.new(reply_mail.mail).perform
        expect(channel).to be_nil
      end

      it 'process bcc email when account is not in skip config' do
        channel_email.update(email: 'test@example.com')
        reply_mail.mail['to'] = nil
        reply_mail.mail['bcc'] = 'test@example.com'

        # Configure other account IDs but not this one
        other_account_ids = [123, 456, 789]
        allow(GlobalConfigService).to receive(:load)
          .with('SKIP_INCOMING_BCC_PROCESSING', '')
          .and_return(other_account_ids.join(','))

        channel = described_class.new(reply_mail.mail).perform
        expect(channel).to eq(channel_email)
      end

      it 'process bcc email when skip config is empty' do
        channel_email.update(email: 'test@example.com')
        reply_mail.mail['to'] = nil
        reply_mail.mail['bcc'] = 'test@example.com'

        allow(GlobalConfigService).to receive(:load)
          .with('SKIP_INCOMING_BCC_PROCESSING', '')
          .and_return('')

        channel = described_class.new(reply_mail.mail).perform
        expect(channel).to eq(channel_email)
      end

      it 'process bcc email when skip config is nil' do
        channel_email.update(email: 'test@example.com')
        reply_mail.mail['to'] = nil
        reply_mail.mail['bcc'] = 'test@example.com'

        allow(GlobalConfigService).to receive(:load)
          .with('SKIP_INCOMING_BCC_PROCESSING', '')
          .and_return(nil)

        channel = described_class.new(reply_mail.mail).perform
        expect(channel).to eq(channel_email)
      end

      it 'return channel with X-Original-To email' do
        channel_email.update(email: 'test@example.com')
        reply_mail.mail['to'] = nil
        reply_mail.mail['X-Original-To'] = 'test@example.com'
        channel = described_class.new(reply_mail.mail).perform
        expect(channel).to eq(channel_email)
      end

      it 'process X-Original-To email even when account is configured to skip BCC processing' do
        channel_email.update(email: 'test@example.com')
        reply_mail.mail['to'] = nil
        reply_mail.mail['X-Original-To'] = 'test@example.com'

        allow(GlobalConfigService).to receive(:load)
          .with('SKIP_INCOMING_BCC_PROCESSING', '')
          .and_return(channel_email.account_id.to_s)

        channel = described_class.new(reply_mail.mail).perform
        expect(channel).to eq(channel_email)
      end
    end
  end
end
