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
  let!(:conversation) { create(:conversation, account: account, identifier: message_params[:event][:thread_ts]) }

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('files.slack.com').and_return(['93.184.216.34'])
    stub_request(:get, 'https://files.slack.com/files-pri/TLST3048H-F0000000001/sample.png').to_return(
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
        allow(builder).to receive(:resolve_slack_sender).and_return([nil, nil, nil])
        2.times.each { builder.perform }
        expect(conversation.messages.count).to eql(messages_count + 1)
        expect(conversation.messages.last.content).to eql('this is test https://chatwoot.com Hey @Sojan Test again')
      end

      it 'creates message' do
        expect(hook).not_to be_nil
        messages_count = conversation.messages.count
        builder = described_class.new(message_params)
        allow(builder).to receive(:resolve_slack_sender).and_return([nil, nil, nil])
        builder.perform
        expect(conversation.messages.count).to eql(messages_count + 1)
        expect(conversation.messages.last.content).to eql('this is test https://chatwoot.com Hey @Sojan Test again')
      end

      it 'creates a private note' do
        expect(hook).not_to be_nil
        messages_count = conversation.messages.count
        builder = described_class.new(private_message_params)
        allow(builder).to receive(:resolve_slack_sender).and_return([nil, nil, nil])
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
        allow(builder).to receive(:resolve_slack_sender).and_return([nil, nil, nil])
        builder.perform
        expect(conversation.messages.count).to eql(messages_count)
      end

      it 'saves attachment if params files present' do
        expect(hook).not_to be_nil
        messages_count = conversation.messages.count
        builder = described_class.new(message_with_attachments)
        allow(builder).to receive(:resolve_slack_sender).and_return([nil, nil, nil])
        builder.perform
        expect(conversation.messages.count).to eql(messages_count + 1)
        expect(conversation.messages.last.content).to eql('this is test https://chatwoot.com Hey @Sojan Test again')
        expect(conversation.messages.last.attachments).to be_any
      end

      it 'sends the hook token when downloading from the Slack file host' do
        builder = described_class.new(message_with_attachments)
        allow(builder).to receive(:resolve_slack_sender).and_return([nil, nil, nil])
        builder.perform

        expect(
          a_request(:get, 'https://files.slack.com/files-pri/TLST3048H-F0000000001/sample.png')
            .with(headers: { 'Authorization' => "Bearer #{hook.access_token}" })
        ).to have_been_made.once
      end

      [
        'https://files.example.com/sample.png',
        'https://files.slack.com.example.com/sample.png',
        'http://files.slack.com/files-pri/TLST3048H-F0000000001/sample.png',
        'https://files.slack.com:8443/files-pri/TLST3048H-F0000000001/sample.png',
        'https://user@files.slack.com/files-pri/TLST3048H-F0000000001/sample.png',
        'not a url'
      ].each do |url|
        it "skips the attachment without fetching for #{url}" do
          message_with_attachments[:event][:files][0][:url_private] = url
          builder = described_class.new(message_with_attachments)
          allow(builder).to receive(:resolve_slack_sender).and_return([nil, nil, nil])

          expect { builder.perform }.to change(conversation.messages, :count).by(1)
          expect(conversation.messages.last.attachments).to be_empty
          expect(a_request(:any, /.*/)).not_to have_been_made
        end
      end

      it 'follows a redirect to another host without the hook token' do
        allow(Resolv).to receive(:getaddresses).with('files.example.com').and_return(['93.184.216.34'])
        stub_request(:get, 'https://files.slack.com/files-pri/TLST3048H-F0000000001/sample.png')
          .to_return(status: 302, headers: { 'Location' => 'https://files.example.com/sample.png' })
        redirected_authorization = :not_requested
        stub_request(:get, 'https://files.example.com/sample.png')
          .with do |request|
            redirected_authorization = request.headers['Authorization']
            true
          end
          .to_return(status: 200, body: File.read('spec/assets/sample.png'), headers: { 'Content-Type' => 'image/png' })
        builder = described_class.new(message_with_attachments)
        allow(builder).to receive(:resolve_slack_sender).and_return([nil, nil, nil])

        expect { builder.perform }.to change(conversation.messages, :count).by(1)
        expect(conversation.messages.last.attachments.first.file.byte_size).to eq(File.size('spec/assets/sample.png'))
        expect(redirected_authorization).to be_nil
      end

      it 'skips the attachment when the download is refused' do
        allow(Resolv).to receive(:getaddresses).with('files.example.com').and_return(['192.0.2.10'])
        stub_request(:get, 'https://files.slack.com/files-pri/TLST3048H-F0000000001/sample.png')
          .to_return(status: 302, headers: { 'Location' => 'https://files.example.com/sample.png' })
        builder = described_class.new(message_with_attachments)
        allow(builder).to receive(:resolve_slack_sender).and_return([nil, nil, nil])

        expect { builder.perform }.to change(conversation.messages, :count).by(1)
        expect(conversation.messages.last.attachments).to be_empty
        expect(a_request(:get, 'https://files.example.com/sample.png')).not_to have_been_made
      end

      it 'raises without creating the message when the Slack file host times out' do
        stub_request(:get, 'https://files.slack.com/files-pri/TLST3048H-F0000000001/sample.png').to_timeout
        builder = described_class.new(message_with_attachments)
        allow(builder).to receive(:resolve_slack_sender).and_return([nil, nil, nil])

        expect { builder.perform }.to raise_error(SafeFetch::FetchError)
          .and not_change(conversation.messages, :count)
      end

      it 'raises without creating the message when the Slack file host returns a server error' do
        stub_request(:get, 'https://files.slack.com/files-pri/TLST3048H-F0000000001/sample.png').to_return(status: 503)
        builder = described_class.new(message_with_attachments)
        allow(builder).to receive(:resolve_slack_sender).and_return([nil, nil, nil])

        expect { builder.perform }.to raise_error(SafeFetch::HttpError)
          .and not_change(conversation.messages, :count)
      end

      it 'ignore message if it is postback of CW attachment message' do
        expect(hook).not_to be_nil
        messages_count = conversation.messages.count
        message_with_attachments[:event][:text] = 'Attached File!'
        builder = described_class.new(message_with_attachments)

        allow(builder).to receive(:resolve_slack_sender).and_return([nil, nil, nil])
        builder.perform

        expect(conversation.messages.count).to eql(messages_count)
      end

      it 'handles different file types correctly' do
        expect(hook).not_to be_nil
        video_attachment_params = message_with_attachments.deep_dup
        video_attachment_params[:event][:files][0][:filetype] = 'mp4'
        video_attachment_params[:event][:files][0][:mimetype] = 'video/mp4'

        builder = described_class.new(video_attachment_params)
        allow(builder).to receive(:resolve_slack_sender).and_return([nil, nil, nil])

        expect { builder.perform }.not_to raise_error
        expect(conversation.messages.last.attachments).to be_any
      end
    end

    context 'when the same thread identifier exists in another account' do
      let(:other_conversation) { create(:conversation, identifier: message_params[:event][:thread_ts]) }
      let!(:conversation) do
        other_conversation
        create(:conversation, account: account, identifier: message_params[:event][:thread_ts])
      end

      it 'creates the message only in the conversation of the hook account' do
        builder = described_class.new(message_params)
        allow(builder).to receive(:resolve_slack_sender).and_return([nil, nil, nil])

        expect { builder.perform }.to change(conversation.messages, :count).by(1)
        expect(other_conversation.messages.count).to eq(0)
      end
    end

    context 'when the same slack channel is connected to two accounts' do
      let!(:conversation) { create(:conversation, account: account) }
      let!(:second_conversation) { create(:conversation, account: create(:account), identifier: message_params[:event][:thread_ts]) }

      before do
        create(:integrations_hook, account: second_conversation.account, reference_id: message_params[:event][:channel])
      end

      it 'creates the message in the conversation of the account that owns the thread' do
        builder = described_class.new(message_params)
        allow(builder).to receive(:resolve_slack_sender).and_return([nil, nil, nil])

        expect { builder.perform }.to change(second_conversation.messages, :count).by(1)
        expect(conversation.messages.count).to eq(0)
      end
    end

    context 'when a non slack hook has the same reference id' do
      let(:hook) { create(:integrations_hook, :linear, account: account, reference_id: message_params[:event][:channel]) }

      it 'does not create a message' do
        builder = described_class.new(message_params)
        allow(builder).to receive(:resolve_slack_sender).and_return([nil, nil, nil])
        expect { builder.perform }.not_to change(Message, :count)
      end
    end

    context 'when resolving slack sender' do
      let(:builder) { described_class.new(message_params) }

      before do
        allow(builder).to receive(:slack_client).and_return(slack_client)
      end

      context 'when slack user email matches a chatwoot agent' do
        before do
          create(:user, account: conversation.account, email: 'agent@example.com')
          slack_response = {
            user: {
              profile: { email: 'agent@example.com', display_name: 'Muhsin K', image_192: 'https://avatars.slack-edge.com/avatar.png' },
              real_name: 'Muhsin K',
              name: 'muhsink'
            }
          }
          allow(slack_client).to receive(:users_info)
            .with(user: message_params[:event][:user])
            .and_return(slack_response)
        end

        it 'sets the matched agent as message sender' do
          builder.perform
          expect(conversation.messages.last.sender).to eq(conversation.account.users.from_email('agent@example.com'))
        end

        it 'does not store sender_name in additional_attributes' do
          builder.perform
          expect(conversation.messages.last.additional_attributes).not_to have_key('sender_name')
        end
      end

      context 'when slack user email does not match any chatwoot agent' do
        before do
          slack_response = {
            user: {
              profile: { email: 'unknown@example.com', display_name: 'Muhsin K', image_192: 'https://avatars.slack-edge.com/avatar.png' },
              real_name: 'Muhsin K',
              name: 'muhsink'
            }
          }
          allow(slack_client).to receive(:users_info)
            .with(user: message_params[:event][:user])
            .and_return(slack_response)
        end

        it 'saves sender_name from slack display_name in additional_attributes' do
          builder.perform
          expect(conversation.messages.last.sender).to be_nil
          expect(conversation.messages.last.additional_attributes['sender_name']).to eq('Muhsin K')
        end

        it 'saves sender_avatar_url from slack profile image in additional_attributes' do
          builder.perform
          expect(conversation.messages.last.additional_attributes['sender_avatar_url'])
            .to eq('https://avatars.slack-edge.com/avatar.png')
        end

        it 'falls back to real_name when display_name is blank' do
          allow(slack_client).to receive(:users_info).and_return({
                                                                   user: {
                                                                     profile: { email: 'unknown@example.com', display_name: '',
                                                                                image_192: nil }, real_name: 'Muhsin K', name: 'muhsink'
                                                                   }
                                                                 })
          builder.perform
          expect(conversation.messages.last.additional_attributes['sender_name']).to eq('Muhsin K')
        end

        it 'falls back to slack username when display_name and real_name are both blank' do
          allow(slack_client).to receive(:users_info).and_return({
                                                                   user: {
                                                                     profile: { email: 'unknown@example.com', display_name: '',
                                                                                image_192: nil }, real_name: '', name: 'muhsink'
                                                                   }
                                                                 })
          builder.perform
          expect(conversation.messages.last.additional_attributes['sender_name']).to eq('muhsink')
        end
      end

      context 'when the slack API call raises an error' do
        before do
          allow(slack_client).to receive(:users_info).and_raise(StandardError, 'API error')
        end

        it 'creates the message with nil sender' do
          expect { builder.perform }.not_to raise_error
          expect(conversation.messages.last.sender).to be_nil
        end

        it 'does not store sender info in additional_attributes' do
          builder.perform
          expect(conversation.messages.last.additional_attributes).not_to have_key('sender_name')
          expect(conversation.messages.last.additional_attributes).not_to have_key('sender_avatar_url')
        end
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
