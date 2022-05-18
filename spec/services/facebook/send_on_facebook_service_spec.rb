require 'rails_helper'

describe Facebook::SendOnFacebookService do
  subject(:send_reply_service) { described_class.new(message: message) }

  before do
    allow(Facebook::Messenger::Subscriptions).to receive(:subscribe).and_return(true)
    allow(bot).to receive(:deliver).and_return({ recipient_id: '1008372609250235', message_id: 'mid.1456970487936:c34767dfe57ee6e339' }.to_json)
    create(:message, message_type: :incoming, inbox: facebook_inbox, account: account, conversation: conversation)
  end

  let!(:account) { create(:account) }
  let(:bot) { class_double('Facebook::Messenger::Bot').as_stubbed_const }
  let!(:widget_inbox) { create(:inbox, account: account) }
  let!(:facebook_channel) { create(:channel_facebook_page, account: account) }
  let!(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: facebook_inbox) }
  let(:conversation) { create(:conversation, contact: contact, inbox: facebook_inbox, contact_inbox: contact_inbox) }

  describe '#perform' do
    context 'without reply' do
      it 'if message is private' do
        message = create(:message, message_type: 'outgoing', private: true, inbox: facebook_inbox, account: account)
        ::Facebook::SendOnFacebookService.new(message: message).perform
        expect(bot).not_to have_received(:deliver)
      end

      it 'if inbox channel is not facebook page' do
        message = create(:message, message_type: 'outgoing', inbox: widget_inbox, account: account)
        expect { ::Facebook::SendOnFacebookService.new(message: message).perform }.to raise_error 'Invalid channel service was called'
        expect(bot).not_to have_received(:deliver)
      end

      it 'if message is not outgoing' do
        message = create(:message, message_type: 'incoming', inbox: facebook_inbox, account: account)
        ::Facebook::SendOnFacebookService.new(message: message).perform
        expect(bot).not_to have_received(:deliver)
      end

      it 'if message has an FB ID' do
        message = create(:message, message_type: 'outgoing', inbox: facebook_inbox, account: account, source_id: SecureRandom.uuid)
        ::Facebook::SendOnFacebookService.new(message: message).perform
        expect(bot).not_to have_received(:deliver)
      end
    end

    context 'with reply' do
      it 'if message is sent from chatwoot and is outgoing' do
        message = create(:message, message_type: 'outgoing', inbox: facebook_inbox, account: account, conversation: conversation)
        ::Facebook::SendOnFacebookService.new(message: message).perform
        expect(bot).to have_received(:deliver)
      end

      it 'if message with attachment is sent from chatwoot and is outgoing' do
        message = build(:message, message_type: 'outgoing', inbox: facebook_inbox, account: account, conversation: conversation)
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: File.open(Rails.root.join('spec/assets/avatar.png')), filename: 'avatar.png', content_type: 'image/png')
        message.save!
        allow(attachment).to receive(:download_url).and_return('url1')
        ::Facebook::SendOnFacebookService.new(message: message).perform
        expect(bot).to have_received(:deliver).with({
                                                      recipient: { id: contact_inbox.source_id },
                                                      message: { text: message.content },
                                                      messaging_type: 'MESSAGE_TAG',
                                                      tag: 'ACCOUNT_UPDATE'
                                                    }, { page_id: facebook_channel.page_id })
        expect(bot).to have_received(:deliver).with({
                                                      recipient: { id: contact_inbox.source_id },
                                                      message: {
                                                        attachment: {
                                                          type: 'image',
                                                          payload: {
                                                            url: 'url1'
                                                          }
                                                        }
                                                      },
                                                      messaging_type: 'MESSAGE_TAG',
                                                      tag: 'ACCOUNT_UPDATE'
                                                    }, { page_id: facebook_channel.page_id })
      end
    end
  end
end
