require 'rails_helper'

describe Integrations::Slack::SendOnSlackService do
  let!(:contact) { create(:contact) }
  let(:channel_email) { create(:channel_email) }
  let!(:conversation) { create(:conversation, inbox: channel_email.inbox, contact: contact, identifier: nil) }
  let(:account) { conversation.account }
  let!(:hook) { create(:integrations_hook, account: account) }
  let!(:message) do
    create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation)
  end
  let!(:template_message) do
    create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, message_type: :template)
  end

  let(:slack_message) { double }
  let(:file_attachment) { double }
  let(:slack_message_content) { double }
  let(:slack_client) { double }
  let(:builder) { described_class.new(message: message, hook: hook) }
  let(:link_builder) { described_class.new(message: nil, hook: hook) }
  let(:conversation_link) do
    "<#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/conversations/#{conversation.display_id}|Click here> to view the conversation."
  end

  before do
    allow(builder).to receive(:slack_client).and_return(slack_client)
    allow(link_builder).to receive(:slack_client).and_return(slack_client)
    allow(slack_message).to receive(:[]).with('ts').and_return('12345.6789')
    allow(slack_message).to receive(:[]).with('message').and_return(slack_message_content)
    allow(slack_message_content).to receive(:[]).with('ts').and_return('6789.12345')
    allow(slack_message_content).to receive(:[]).with('thread_ts').and_return('12345.6789')
  end

  describe '#perform' do
    context 'without identifier' do
      it 'updates slack thread id in conversation' do
        inbox = conversation.inbox

        expect(slack_client).to receive(:chat_postMessage).with(
          channel: hook.reference_id,
          text: "\n*Inbox:* #{inbox.name} (#{inbox.inbox_type})\n#{conversation_link}\n\n#{message.content}",
          username: "#{message.sender.name} (Contact)",
          thread_ts: nil,
          icon_url: anything,
          unfurl_links: false
        ).and_return(slack_message)

        builder.perform

        expect(conversation.reload.identifier).to eq '12345.6789'
      end

      context 'with subject line in email' do
        let(:message) do
          create(:message,
                 content_attributes: { 'email': { 'subject': 'Sample subject line' } },
                 content: 'Sample Body',
                 account: conversation.account,
                 inbox: conversation.inbox, conversation: conversation)
        end

        it 'creates slack message with subject line' do
          inbox = conversation.inbox

          expect(slack_client).to receive(:chat_postMessage).with(
            channel: hook.reference_id,
            text: "\n*Inbox:* #{inbox.name} (#{inbox.inbox_type})\n#{conversation_link}\n" \
                  "*Subject:* Sample subject line\n\n\n#{message.content}",
            username: "#{message.sender.name} (Contact)",
            thread_ts: nil,
            icon_url: anything,
            unfurl_links: false
          ).and_return(slack_message)

          builder.perform

          expect(conversation.reload.identifier).to eq '12345.6789'
        end
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
          icon_url: anything,
          unfurl_links: true
        ).and_return(slack_message)

        builder.perform

        expect(message.external_source_id_slack).to eq 'cw-origin-6789.12345'
      end

      it 'sent message will send to the the previous thread if the slack disconnects and connects to a same channel.' do
        allow(slack_message).to receive(:[]).with('message').and_return({ 'thread_ts' => conversation.identifier })
        expect(slack_client).to receive(:chat_postMessage).with(
          channel: hook.reference_id,
          text: message.content,
          username: "#{message.sender.name} (Contact)",
          thread_ts: conversation.identifier,
          icon_url: anything,
          unfurl_links: true
        ).and_return(slack_message)

        builder.perform

        expect(conversation.identifier).to eq 'random_slack_thread_ts'
      end

      it 'sent message will create a new thread if the slack disconnects and connects to a different channel' do
        allow(slack_message).to receive(:[]).with('message').and_return({ 'thread_ts' => nil })
        allow(slack_message).to receive(:[]).with('ts').and_return('1691652432.896169')

        hook.update!(reference_id: 'C12345')

        expect(slack_client).to receive(:chat_postMessage).with(
          channel: 'C12345',
          text: message.content,
          username: "#{message.sender.name} (Contact)",
          thread_ts: conversation.identifier,
          icon_url: anything,
          unfurl_links: true
        ).and_return(slack_message)

        builder.perform

        expect(hook.reload.reference_id).to eq 'C12345'
        expect(conversation.identifier).to eq '1691652432.896169'
      end

      it 'sent lnk unfurl to slack' do
        unflur_payload = { :channel => 'channel',
                           :ts => 'timestamp',
                           :unfurls =>
           { :'https://qa.chatwoot.com/app/accounts/1/conversations/1' =>
             { :blocks => [{ :type => 'section',
                             :text => { :type => 'plain_text', :text => 'This is a plain text section block.', :emoji => true } }] } } }
        allow(slack_client).to receive(:chat_unfurl).with(unflur_payload)
        link_builder.link_unfurl(unflur_payload)
        expect(slack_client).to have_received(:chat_unfurl).with(unflur_payload)
      end

      it 'sent attachment on slack' do
        expect(slack_client).to receive(:chat_postMessage).with(
          channel: hook.reference_id,
          text: message.content,
          username: "#{message.sender.name} (Contact)",
          thread_ts: conversation.identifier,
          icon_url: anything,
          unfurl_links: true
        ).and_return(slack_message)

        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')

        expect(slack_client).to receive(:files_upload_v2).with(
          filename: attachment.file.filename,
          content: anything,
          channel_id: hook.reference_id,
          thread_ts: conversation.identifier,
          initial_comment: 'Attached File!'
        ).and_return(file_attachment)

        message.save!

        builder.perform

        expect(message.external_source_id_slack).to eq 'cw-origin-6789.12345'
        expect(message.attachments).to be_any
      end

      it 'will not call file_upload if attachment does not have a file (e.g facebook - fallback type)' do
        expect(slack_client).to receive(:chat_postMessage).with(
          channel: hook.reference_id,
          text: message.content,
          username: "#{message.sender.name} (Contact)",
          thread_ts: conversation.identifier,
          icon_url: anything,
          unfurl_links: true
        ).and_return(slack_message)

        message.attachments.new(account_id: message.account_id, file_type: :fallback)

        expect(slack_client).not_to receive(:files_upload)

        message.save!

        builder.perform

        expect(message.external_source_id_slack).to eq 'cw-origin-6789.12345'
        expect(message.attachments).to be_any
      end

      it 'sent a template message on slack' do
        builder = described_class.new(message: template_message, hook: hook)
        allow(builder).to receive(:slack_client).and_return(slack_client)
        template_message.update!(sender: nil)
        expect(slack_client).to receive(:chat_postMessage).with(
          channel: hook.reference_id,
          text: template_message.content,
          username: 'Bot',
          thread_ts: conversation.identifier,
          icon_url: anything,
          unfurl_links: true
        ).and_return(slack_message)

        builder.perform

        expect(template_message.external_source_id_slack).to eq 'cw-origin-6789.12345'
      end

      it 'sent a activity message on slack' do
        template_message.update!(message_type: :activity)
        template_message.update!(sender: nil)
        builder = described_class.new(message: template_message, hook: hook)
        allow(builder).to receive(:slack_client).and_return(slack_client)
        expect(slack_client).to receive(:chat_postMessage).with(
          channel: hook.reference_id,
          text: "_#{template_message.content}_",
          username: 'System',
          thread_ts: conversation.identifier,
          icon_url: anything,
          unfurl_links: true
        ).and_return(slack_message)

        builder.perform
        expect(template_message.external_source_id_slack).to eq 'cw-origin-6789.12345'
      end

      it 'disables hook on Slack AccountInactive error' do
        expect(slack_client).to receive(:chat_postMessage).with(
          channel: hook.reference_id,
          text: message.content,
          username: "#{message.sender.name} (Contact)",
          thread_ts: conversation.identifier,
          icon_url: anything,
          unfurl_links: true
        ).and_raise(Slack::Web::Api::Errors::AccountInactive.new('Account disconnected'))

        allow(hook).to receive(:prompt_reauthorization!)

        builder.perform
        expect(hook).to be_disabled
        expect(hook).to have_received(:prompt_reauthorization!)
      end

      it 'disables hook on Slack MissingScope error' do
        expect(slack_client).to receive(:chat_postMessage).with(
          channel: hook.reference_id,
          text: message.content,
          username: "#{message.sender.name} (Contact)",
          thread_ts: conversation.identifier,
          icon_url: anything,
          unfurl_links: true
        ).and_raise(Slack::Web::Api::Errors::MissingScope.new('Account disconnected'))

        allow(hook).to receive(:prompt_reauthorization!)

        builder.perform
        expect(hook).to be_disabled
        expect(hook).to have_received(:prompt_reauthorization!)
      end

      it 'logs MissingScope error during link unfurl' do
        unflur_payload = { channel: 'channel', ts: 'timestamp', unfurls: {} }
        error = Slack::Web::Api::Errors::MissingScope.new('Missing required scope')

        expect(slack_client).to receive(:chat_unfurl)
          .with(unflur_payload)
          .and_raise(error)

        expect(Rails.logger).to receive(:warn).with('Slack: Missing scope error: Missing required scope')

        link_builder.link_unfurl(unflur_payload)
      end
    end

    context 'when message contains mentions' do
      it 'sends formatted message to slack along with inbox name when identifier not present' do
        inbox = conversation.inbox
        message.update!(content: "Hi [@#{contact.name}](mention://user/#{contact.id}/#{contact.name}), welcome to Chatwoot!")
        formatted_message_text = message.content.gsub(RegexHelper::MENTION_REGEX, '\1')

        expect(slack_client).to receive(:chat_postMessage).with(
          channel: hook.reference_id,
          text: "\n*Inbox:* #{inbox.name} (#{inbox.inbox_type})\n#{conversation_link}\n\n#{formatted_message_text}",
          username: "#{message.sender.name} (Contact)",
          thread_ts: nil,
          icon_url: anything,
          unfurl_links: false
        ).and_return(slack_message)

        builder.perform
      end

      it 'sends formatted message to slack when identifier is present' do
        conversation.update!(identifier: 'random_slack_thread_ts')
        message.update!(content: "Hi [@#{contact.name}](mention://user/#{contact.id}/#{contact.name}), welcome to Chatwoot!")
        formatted_message_text = message.content.gsub(RegexHelper::MENTION_REGEX, '\1')

        expect(slack_client).to receive(:chat_postMessage).with(
          channel: hook.reference_id,
          text: formatted_message_text,
          username: "#{message.sender.name} (Contact)",
          thread_ts: 'random_slack_thread_ts',
          icon_url: anything,
          unfurl_links: true
        ).and_return(slack_message)

        builder.perform
      end

      it 'will not throw error if message content is nil' do
        message.update!(content: nil)
        conversation.update!(identifier: 'random_slack_thread_ts')

        expect { builder.perform }.not_to raise_error
      end
    end
  end
end
