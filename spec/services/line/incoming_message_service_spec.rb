require 'rails_helper'

describe Line::IncomingMessageService do
  let!(:line_channel) { create(:channel_line) }
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

  describe '#perform' do
    context 'when valid text message params' do
      it 'creates appropriate conversations, message and contacts' do
        line_bot = double
        line_user_profile = double
        allow(Line::Bot::Client).to receive(:new).and_return(line_bot)
        allow(line_bot).to receive(:get_profile).and_return(line_user_profile)
        allow(line_user_profile).to receive(:body).and_return(
          {
            'displayName': 'LINE Test',
            'userId': 'U4af4980629',
            'pictureUrl': 'https://test.com'
          }.to_json
        )
        described_class.new(inbox: line_channel.inbox, params: params).perform
        expect(line_channel.inbox.conversations).not_to eq(0)
        expect(Contact.all.first.name).to eq('LINE Test')
        expect(Contact.all.first.additional_attributes['social_line_user_id']).to eq('U4af4980629')
        expect(line_channel.inbox.messages.first.content).to eq('Hello, world')
      end
    end

    context 'when valid sticker message params' do
      it 'creates appropriate conversations, message and contacts' do
        line_bot = double
        line_user_profile = double
        allow(Line::Bot::Client).to receive(:new).and_return(line_bot)
        allow(line_bot).to receive(:get_profile).and_return(line_user_profile)
        allow(line_user_profile).to receive(:body).and_return(
          {
            'displayName': 'LINE Test',
            'userId': 'U4af4980629',
            'pictureUrl': 'https://test.com'
          }.to_json
        )
        described_class.new(inbox: line_channel.inbox, params: sticker_params).perform
        expect(line_channel.inbox.conversations).not_to eq(0)
        expect(Contact.all.first.name).to eq('LINE Test')
        expect(line_channel.inbox.messages.first.content).to eq('![sticker-52002738](https://stickershop.line-scdn.net/stickershop/v1/sticker/52002738/android/sticker.png)')
      end
    end

    context 'when valid image message params' do
      it 'creates appropriate conversations, message and contacts' do
        line_bot = double
        line_user_profile = double
        allow(Line::Bot::Client).to receive(:new).and_return(line_bot)
        allow(line_bot).to receive(:get_profile).and_return(line_user_profile)
        file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')
        allow(line_bot).to receive(:get_message_content).and_return(
          OpenStruct.new({
                           body: Base64.encode64(file.read),
                           content_type: 'image/png'
                         })
        )
        allow(line_user_profile).to receive(:body).and_return(
          {
            'displayName': 'LINE Test',
            'userId': 'U4af4980629',
            'pictureUrl': 'https://test.com'
          }.to_json
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
        line_bot = double
        line_user_profile = double
        allow(Line::Bot::Client).to receive(:new).and_return(line_bot)
        allow(line_bot).to receive(:get_profile).and_return(line_user_profile)
        file = fixture_file_upload(Rails.root.join('spec/assets/sample.mp4'), 'video/mp4')
        allow(line_bot).to receive(:get_message_content).and_return(
          OpenStruct.new({
                           body: Base64.encode64(file.read),
                           content_type: 'video/mp4'
                         })
        )
        allow(line_user_profile).to receive(:body).and_return(
          {
            'displayName': 'LINE Test',
            'userId': 'U4af4980629',
            'pictureUrl': 'https://test.com'
          }.to_json
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
  end
end
