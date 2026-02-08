require 'rails_helper'

describe Integrations::Slack::IncomingMessageBuilder do
  let(:account) { create(:account) }
  let(:message_params) { slack_message_stub }
  let(:builder) { described_class.new(hook: hook) }
  let(:private_message_params) do
    {
      team_id: 'TLST3048H',
      api_app_id: 'A012S5UETV4',
      event: message_event.merge({ text: 'pRivate: A private note message' }),
      type: 'event_callback',
      event_time: 1_588_623_033
    }
  end
  let(:sub_type_message) do
    {
      team_id: 'TLST3048H',
      api_app_id: 'A012S5UETV4',
      event: message_event.merge({ type: 'message', subtype: 'bot_message' }),
      type: 'event_callback',
      event_time: 1_588_623_033
    }
  end
  let(:message_without_user) do
    {
      team_id: 'TLST3048H',
      api_app_id: 'A012S5UETV4',
      event: message_event.merge({ type: 'message', user: nil }),
      type: 'event_callback',
      event_time: 1_588_623_033
    }
  end
  let(:slack_client) { double }
  let(:link_unfurl_service) { double }
  let(:message_with_attachments) { slack_attachment_stub }
  let(:message_without_thread_ts) { slack_message_stub_without_thread_ts }
  let(:verification_params) { slack_url_verification_stub }

  let!(:hook) { create(:integrations_hook, account: account, reference_id: message_params[:event][:channel]) }
  let!(:conversation) { create(:conversation, identifier: message_params[:event][:thread_ts]) }

  before do
    stub_request(:get, 'https://chatwoot-assets.local/sample.png').to_return(
      status: 200,
      body: File.read('spec/assets/sample.png'),
      headers: {}
    )
  end

  describe '#perform' do
    context 'when url verification' do
      it 'return challenge code as response' do
        builder = described_class.new(verification_params)
        response = builder.perform
        expect(response[:challenge]).to eql(verification_params[:challenge])
      end
    end

    context 'when message creation' do
      it 'doesnot create message if thread info is missing' do
        messages_count = conversation.messages.count
        builder = described_class.new(message_without_thread_ts)
        builder.perform
        expect(conversation.messages.count).to eql(messages_count)
      end

      it 'does not create message if message already exists' do
        expect(hook).not_to be_nil
        messages_count = conversation.messages.count
        builder = described_class.new(message_params)
        allow(builder).to receive(:sender).and_return(nil)
        2.times.each { builder.perform }
        expect(conversation.messages.count).to eql(messages_count + 1)
        expect(conversation.messages.last.content).to eql('this is test https://chatwoot.com Hey @Sojan Test again')
      end

      it 'creates message' do
        expect(hook).not_to be_nil
        messages_count = conversation.messages.count
        builder = described_class.new(message_params)
        allow(builder).to receive(:sender).and_return(nil)
        builder.perform
        expect(conversation.messages.count).to eql(messages_count + 1)
        expect(conversation.messages.last.content).to eql('this is test https://chatwoot.com Hey @Sojan Test again')
      end

      it 'creates a private note' do
        expect(hook).not_to be_nil
        messages_count = conversation.messages.count
        builder = described_class.new(private_message_params)
        allow(builder).to receive(:sender).and_return(nil)
        builder.perform
        expect(conversation.messages.count).to eql(messages_count + 1)
        expect(conversation.messages.last.content).to eql('pRivate: A private note message')
        expect(conversation.messages.last.private).to be(true)
      end

      it 'does not create message for invalid event type' do
        messages_count = conversation.messages.count
        message_params[:type] = 'invalid_event_type'
        builder = described_class.new(message_params)
        builder.perform
        expect(conversation.messages.count).to eql(messages_count)
      end

      it 'does not create message for invalid event name' do
        messages_count = conversation.messages.count
        message_params[:event][:type] = 'invalid_event_name'
        builder = described_class.new(message_params)
        builder.perform
        expect(conversation.messages.count).to eql(messages_count)
      end

      it 'does not create message for message sub type events' do
        messages_count = conversation.messages.count
        builder = described_class.new(sub_type_message)
        builder.perform
        expect(conversation.messages.count).to eql(messages_count)
      end

      it 'does not create message if user is missing' do
        messages_count = conversation.messages.count
        builder = described_class.new(message_without_user)
        builder.perform
        expect(conversation.messages.count).to eql(messages_count)
      end

      it 'does not create message for invalid event type and event files is not present' do
        messages_count = conversation.messages.count
        message_with_attachments[:event][:files] = nil
        builder = described_class.new(message_with_attachments)
        allow(builder).to receive(:sender).and_return(nil)
        builder.perform
        expect(conversation.messages.count).to eql(messages_count)
      end

      it 'saves attachment if params files present' do
        expect(hook).not_to be_nil
        messages_count = conversation.messages.count
        builder = described_class.new(message_with_attachments)
        allow(builder).to receive(:sender).and_return(nil)
        builder.perform
        expect(conversation.messages.count).to eql(messages_count + 1)
        expect(conversation.messages.last.content).to eql('this is test https://chatwoot.com Hey @Sojan Test again')
        expect(conversation.messages.last.attachments).to be_any
      end

      it 'ignore message if it is postback of CW attachment message' do
        expect(hook).not_to be_nil
        messages_count = conversation.messages.count
        message_with_attachments[:event][:text] = 'Attached File!'
        builder = described_class.new(message_with_attachments)

        allow(builder).to receive(:sender).and_return(nil)
        builder.perform

        expect(conversation.messages.count).to eql(messages_count)
      end
    end

    context 'when link shared' do
      let(:link_shared) do
        {
          team_id: 'TLST3048H',
          api_app_id: 'A012S5UETV4',
          event: link_shared_event.merge({ links: [{ url: "https://qa.chatwoot.com/app/accounts/1/conversations/#{conversation.display_id}",
                                                     domain: 'qa.chatwoot.com' }] }),
          type: 'event_callback',
          event_time: 1_588_623_033
        }
      end

      it 'unfurls link' do
        builder = described_class.new(link_shared)
        expect(SlackUnfurlJob).to receive(:perform_later).with(link_shared)
        builder.perform
      end
    end
  end
end
