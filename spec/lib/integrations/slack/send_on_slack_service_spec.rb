require 'rails_helper'

describe Integrations::Slack::SendOnSlackService do
  let!(:contact) { create(:contact) }
  let!(:conversation) { create(:conversation, contact: contact, identifier: nil) }
  let(:account) { conversation.account }
  let!(:hook) { create(:integrations_hook, account: account) }
  let!(:message) do
    create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation)
  end
  let(:slack_message) { double }
  let(:file_attachment) { double }
  let(:slack_message_content) { double }
  let(:slack_client) { double }
  let(:builder) { described_class.new(message: message, hook: hook) }

  before do
    allow(builder).to receive(:slack_client).and_return(slack_client)
    allow(slack_message).to receive(:[]).with('ts').and_return('12345.6789')
    allow(slack_message).to receive(:[]).with('message').and_return(slack_message_content)
    allow(slack_message_content).to receive(:[]).with('ts').and_return('6789.12345')
  end

  describe '#perform' do
    context 'without identifier' do
      it 'updates slack thread id in conversation' do
        inbox = conversation.inbox

        expect(slack_client).to receive(:chat_postMessage).with(
          channel: hook.reference_id,
          text: "\n*Inbox:* #{inbox.name} (#{inbox.inbox_type})\n\n#{message.content}",
          username: "#{message.sender.name} (Contact)",
          thread_ts: nil,
          icon_url: anything
        ).and_return(slack_message)

        builder.perform

        expect(conversation.reload.identifier).to eq '12345.6789'
      end
    end

    context 'with identifier' do
      before do
        conversation.update!(identifier: 'random_slack_thread_ts')
      end

      it 'sent message to slack' do
        expect(slack_client).to receive(:chat_postMessage).with(
          channel: hook.reference_id,
          text: message.content,
          username: "#{message.sender.name} (Contact)",
          thread_ts: conversation.identifier,
          icon_url: anything
        ).and_return(slack_message)

        builder.perform

        expect(message.external_source_id_slack).to eq 'cw-origin-6789.12345'
      end

      it 'sent attachment on slack' do
        expect(slack_client).to receive(:chat_postMessage).with(
          channel: hook.reference_id,
          text: message.content,
          username: "#{message.sender.name} (Contact)",
          thread_ts: conversation.identifier,
          icon_url: anything
        ).and_return(slack_message)

        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: File.open(Rails.root.join('spec/assets/avatar.png')), filename: 'avatar.png', content_type: 'image/png')

        expect(slack_client).to receive(:files_upload).with(hash_including(
                                                              channels: hook.reference_id,
                                                              thread_ts: conversation.identifier,
                                                              initial_comment: 'Attached File!',
                                                              filetype: 'png',
                                                              content: anything,
                                                              filename: attachment.file.filename,
                                                              title: attachment.file.filename
                                                            )).and_return(file_attachment)

        message.save!

        builder.perform

        expect(message.external_source_id_slack).to eq 'cw-origin-6789.12345'
        expect(message.attachments).to be_any
      end

      it 'disables hook on Slack AccountInactive error' do
        expect(slack_client).to receive(:chat_postMessage).with(
          channel: hook.reference_id,
          text: message.content,
          username: "#{message.sender.name} (Contact)",
          thread_ts: conversation.identifier,
          icon_url: anything
        ).and_raise(Slack::Web::Api::Errors::AccountInactive.new('Account disconnected'))

        allow(hook).to receive(:authorization_error!)

        builder.perform
        expect(hook).to be_disabled
        expect(hook).to have_received(:authorization_error!)
      end
    end
  end
end
