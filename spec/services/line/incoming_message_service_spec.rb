require 'rails_helper'

RSpec.describe Line::IncomingMessageService do
  let!(:line_channel) { create(:channel_line) }
  let(:messaging_client) { instance_double(Line::Bot::V2::MessagingApi::ApiClient) }
  let(:blob_client) { instance_double(Line::Bot::V2::MessagingApi::ApiBlobClient) }
  let(:profile) do
    Struct.new(:display_name, :user_id, :picture_url).new(
      'LINE Test',
      'U4af4980629',
      'https://test.com'
    )
  end
  let(:second_profile) do
    Struct.new(:display_name, :user_id, :picture_url).new(
      'LINE Test 2',
      'U4af49806292',
      'https://test.com'
    )
  end
  let(:params) do
    {
      'destination': '2342234234',
      'events': [
        {
          'replyToken': '0f3779fba3b349968c5d07db31eab56f',
          'type': 'message',
          'mode': 'active',
          'timestamp': 1_462_629_479_859,
          'source': {
            'type': 'user',
            'userId': 'U4af4980629'
          },
          'message': {
            'id': '325708',
            'type': 'text',
            'text': 'Hello, world'
          }
        },
        {
          'replyToken': '8cf9239d56244f4197887e939187e19e',
          'type': 'follow',
          'mode': 'active',
          'timestamp': 1_462_629_479_859,
          'source': {
            'type': 'user',
            'userId': 'U4af4980629'
          }
        }
      ]
    }.with_indifferent_access
  end

  let(:follow_params) do
    {
      'destination': '2342234234',
      'events': [
        {
          'replyToken': '8cf9239d56244f4197887e939187e19e',
          'type': 'follow',
          'mode': 'active',
          'timestamp': 1_462_629_479_859,
          'source': {
            'type': 'user',
            'userId': 'U4af4980629'
          }
        }
      ]
    }.with_indifferent_access
  end

  let(:multi_user_params) do
    {
      'destination': '2342234234',
      'events': [
        {
          'replyToken': '0f3779fba3b349968c5d07db31eab56f1',
          'type': 'message',
          'mode': 'active',
          'timestamp': 1_462_629_479_859,
          'source': {
            'type': 'user',
            'userId': 'U4af4980629'
          },
          'message': {
            'id': '3257081',
            'type': 'text',
            'text': 'Hello, world 1'
          }
        },
        {
          'replyToken': '0f3779fba3b349968c5d07db31eab56f2',
          'type': 'message',
          'mode': 'active',
          'timestamp': 1_462_629_479_859,
          'source': {
            'type': 'user',
            'userId': 'U4af49806292'
          },
          'message': {
            'id': '3257082',
            'type': 'text',
            'text': 'Hello, world 2'
          }
        }
      ]
    }.with_indifferent_access
  end

  let(:image_params) do
    {
      'destination': '2342234234',
      'events': [
        {
          'replyToken': '0f3779fba3b349968c5d07db31eab56f',
          'type': 'message',
          'mode': 'active',
          'timestamp': 1_462_629_479_859,
          'source': {
            'type': 'user',
            'userId': 'U4af4980629'
          },
          'message': {
            'type': 'image',
            'id': '354718',
            'contentProvider': {
              'type': 'line'
            }
          }
        },
        {
          'replyToken': '8cf9239d56244f4197887e939187e19e',
          'type': 'follow',
          'mode': 'active',
          'timestamp': 1_462_629_479_859,
          'source': {
            'type': 'user',
            'userId': 'U4af4980629'
          }
        }
      ]
    }.with_indifferent_access
  end

  let(:video_params) do
    {
      'destination': '2342234234',
      'events': [
        {
          'replyToken': '0f3779fba3b349968c5d07db31eab56f',
          'type': 'message',
          'mode': 'active',
          'timestamp': 1_462_629_479_859,
          'source': {
            'type': 'user',
            'userId': 'U4af4980629'
          },
          'message': {
            'type': 'video',
            'id': '354718',
            'contentProvider': {
              'type': 'line'
            }
          }
        },
        {
          'replyToken': '8cf9239d56244f4197887e939187e19e',
          'type': 'follow',
          'mode': 'active',
          'timestamp': 1_462_629_479_859,
          'source': {
            'type': 'user',
            'userId': 'U4af4980629'
          }
        }
      ]
    }.with_indifferent_access
  end

  let(:file_params) do
    {
      'destination': '2342234234',
      'events': [
        {
          'replyToken': '0f3779fba3b349968c5d07db31eab56f',
          'type': 'message',
          'mode': 'active',
          'timestamp': 1_462_629_479_859,
          'source': {
            'type': 'user',
            'userId': 'U4af4980629'
          },
          'message': {
            'type': 'file',
            'id': '354718',
            'fileName': 'contacts.csv',
            'fileSize': 2978
          }
        },
        {
          'replyToken': '8cf9239d56244f4197887e939187e19e',
          'type': 'follow',
          'mode': 'active',
          'timestamp': 1_462_629_479_859,
          'source': {
            'type': 'user',
            'userId': 'U4af4980629'
          }
        }
      ]
    }.with_indifferent_access
  end

  let(:sticker_params) do
    {
      'destination': '2342234234',
      'events': [
        {
          'replyToken': '0f3779fba3b349968c5d07db31eab56f',
          'type': 'message',
          'mode': 'active',
          'timestamp': 1_462_629_479_859,
          'source': {
            'type': 'user',
            'userId': 'U4af4980629'
          },
          'message': {
            'type': 'sticker',
            'id': '1501597916',
            'quoteToken': 'q3Plxr4AgKd...',
            'stickerId': '52002738',
            'packageId': '11537'
          }
        },
        {
          'replyToken': '8cf9239d56244f4197887e939187e19e',
          'type': 'follow',
          'mode': 'active',
          'timestamp': 1_462_629_479_859,
          'source': {
            'type': 'user',
            'userId': 'U4af4980629'
          }
        }
      ]
    }.with_indifferent_access
  end

  before do
    allow(line_channel).to receive(:messaging_api_client).and_return(messaging_client)
    allow(line_channel).to receive(:messaging_api_blob_client).and_return(blob_client)
    allow(messaging_client).to receive(:get_profile).with(user_id: 'U4af4980629').and_return(profile)
    allow(messaging_client).to receive(:get_profile).with(user_id: 'U4af49806292').and_return(second_profile)
  end

  describe '#perform' do
    context 'when non-text message params' do
      it 'does not create conversations, messages and contacts' do
        described_class.new(inbox: line_channel.inbox, params: follow_params).perform

        expect(line_channel.inbox.conversations.size).to eq(0)
        expect(Contact.all.size).to eq(0)
        expect(line_channel.inbox.messages.size).to eq(0)
      end
    end

    context 'when valid text message params' do
      it 'creates appropriate conversations, message and contacts' do
        described_class.new(inbox: line_channel.inbox, params: params).perform

        expect(line_channel.inbox.conversations).not_to eq(0)
        expect(Contact.all.first.name).to eq('LINE Test')
        expect(Contact.all.first.additional_attributes['social_line_user_id']).to eq('U4af4980629')
        expect(line_channel.inbox.messages.first.content).to eq('Hello, world')
      end

      it 'creates appropriate conversations, message and contacts for multi user' do
        described_class.new(inbox: line_channel.inbox, params: multi_user_params).perform

        expect(line_channel.inbox.conversations.size).to eq(2)
        expect(Contact.all.first.name).to eq('LINE Test')
        expect(Contact.all.first.additional_attributes['social_line_user_id']).to eq('U4af4980629')
        expect(Contact.all.last.name).to eq('LINE Test 2')
        expect(Contact.all.last.additional_attributes['social_line_user_id']).to eq('U4af49806292')
        expect(line_channel.inbox.messages.first.content).to eq('Hello, world 1')
        expect(line_channel.inbox.messages.last.content).to eq('Hello, world 2')
      end

      it 'reuses an existing contact matched by line_handle' do
        create(:contact, account: line_channel.inbox.account, custom_attributes: { 'line_handle' => 'U4af4980629' })

        described_class.new(inbox: line_channel.inbox, params: params).perform

        expect(line_channel.inbox.contacts.count).to eq(1)
        expect(line_channel.inbox.contacts.first.additional_attributes['social_line_user_id']).to eq('U4af4980629')
      end

      it 'does not create a duplicate message when the same line message id is received twice' do
        described_class.new(inbox: line_channel.inbox, params: params).perform
        described_class.new(inbox: line_channel.inbox, params: params).perform

        expect(line_channel.inbox.messages.count).to eq(1)
      end
    end

    context 'when valid sticker message params' do
      it 'creates appropriate conversations, message and contacts' do
        described_class.new(inbox: line_channel.inbox, params: sticker_params).perform

        expect(line_channel.inbox.conversations).not_to eq(0)
        expect(Contact.all.first.name).to eq('LINE Test')
        expect(line_channel.inbox.messages.first.content).to eq(
          '![sticker-52002738](https://stickershop.line-scdn.net/stickershop/v1/sticker/52002738/android/sticker.png)'
        )
      end
    end

    context 'when valid image message params' do
      it 'creates appropriate conversations, message and contacts' do
        file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')
        allow(blob_client).to receive(:get_message_content_with_http_info).with(message_id: '354718').and_return(
          [file.read, 200, { 'content-type' => 'image/png' }]
        )

        described_class.new(inbox: line_channel.inbox, params: image_params).perform

        expect(line_channel.inbox.conversations).not_to eq(0)
        expect(Contact.all.first.name).to eq('LINE Test')
        expect(Contact.all.first.additional_attributes['social_line_user_id']).to eq('U4af4980629')
        expect(line_channel.inbox.messages.first.content).to be_nil
        expect(line_channel.inbox.messages.first.attachments.first.file_type).to eq('image')
        expect(line_channel.inbox.messages.first.attachments.first.file.blob.filename.to_s).to eq('media-354718.png')
      end
    end

    context 'when valid video message params' do
      it 'creates appropriate conversations, message and contacts' do
        file = fixture_file_upload(Rails.root.join('spec/assets/sample.mp4'), 'video/mp4')
        allow(blob_client).to receive(:get_message_content_with_http_info).with(message_id: '354718').and_return(
          [file.read, 200, { 'content-type' => 'video/mp4' }]
        )

        described_class.new(inbox: line_channel.inbox, params: video_params).perform

        expect(line_channel.inbox.conversations).not_to eq(0)
        expect(Contact.all.first.name).to eq('LINE Test')
        expect(Contact.all.first.additional_attributes['social_line_user_id']).to eq('U4af4980629')
        expect(line_channel.inbox.messages.first.content).to be_nil
        expect(line_channel.inbox.messages.first.attachments.first.file_type).to eq('video')
        expect(line_channel.inbox.messages.first.attachments.first.file.blob.filename.to_s).to eq('media-354718.mp4')
      end
    end

    context 'when valid file message params' do
      it 'creates appropriate conversations, message and contacts' do
        file = fixture_file_upload(Rails.root.join('spec/assets/contacts.csv'), 'text/csv')
        allow(blob_client).to receive(:get_message_content_with_http_info).with(message_id: '354718').and_return(
          [file.read, 200, { 'content-type' => 'text/csv' }]
        )

        described_class.new(inbox: line_channel.inbox, params: file_params).perform

        expect(line_channel.inbox.conversations).not_to eq(0)
        expect(Contact.all.first.name).to eq('LINE Test')
        expect(Contact.all.first.additional_attributes['social_line_user_id']).to eq('U4af4980629')
        expect(line_channel.inbox.messages.first.content).to be_nil
        expect(line_channel.inbox.messages.first.attachments.first.file_type).to eq('file')
        expect(line_channel.inbox.messages.first.attachments.first.file.blob.filename.to_s).to eq('contacts.csv')
      end
    end

    context 'when lock_to_single_conversation is false' do
      before do
        line_channel.inbox.update(lock_to_single_conversation: false)
      end

      it 'creates a new conversation when all previous conversations are resolved' do
        described_class.new(inbox: line_channel.inbox, params: params).perform

        conversation = line_channel.inbox.conversations.last
        conversation.update(status: :resolved)

        new_params = params.deep_dup
        new_params[:events][0][:message][:id] = '325709'
        new_params[:events][0][:message][:text] = 'Second message'

        described_class.new(inbox: line_channel.inbox, params: new_params).perform

        expect(line_channel.inbox.conversations.count).to eq(2)
        expect(line_channel.inbox.conversations.last.messages.first.content).to eq('Second message')
      end

      it 'uses the existing conversation when there is an unresolved conversation' do
        described_class.new(inbox: line_channel.inbox, params: params).perform

        new_params = params.deep_dup
        new_params[:events][0][:message][:id] = '325709'
        new_params[:events][0][:message][:text] = 'Second message'

        described_class.new(inbox: line_channel.inbox, params: new_params).perform

        expect(line_channel.inbox.conversations.count).to eq(1)
        expect(line_channel.inbox.conversations.last.messages.count).to eq(2)
        expect(line_channel.inbox.conversations.last.messages.last.content).to eq('Second message')
      end
    end

    context 'when lock_to_single_conversation is true' do
      before do
        line_channel.inbox.update(lock_to_single_conversation: true)
      end

      it 'uses the existing conversation even when it is resolved' do
        described_class.new(inbox: line_channel.inbox, params: params).perform

        conversation = line_channel.inbox.conversations.last
        conversation.update(status: :resolved)

        new_params = params.deep_dup
        new_params[:events][0][:message][:id] = '325709'
        new_params[:events][0][:message][:text] = 'Second message'

        described_class.new(inbox: line_channel.inbox, params: new_params).perform

        expect(line_channel.inbox.conversations.count).to eq(1)
        expect(line_channel.inbox.conversations.last.messages.count).to eq(2)
        expect(line_channel.inbox.conversations.last.messages.last.content).to eq('Second message')
      end
    end
  end
end
