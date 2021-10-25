require 'rails_helper'

describe Telegram::IncomingMessageService do
  let!(:telegram_channel) { create(:channel_telegram) }

  describe '#perform' do
    context 'when valid text message params' do
      it 'creates appropriate conversations, message and contacts' do
        params = {
          'update_id' => 2_342_342_343_242,
          'message' => {
            'message_id' => 1,
            'from' => {
              'id' => 23, 'is_bot' => false, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'language_code' => 'en'
            },
            'chat' => { 'id' => 23, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'type' => 'private' },
            'date' => 1_631_132_077, 'text' => 'test'
          }
        }.with_indifferent_access
        described_class.new(inbox: telegram_channel.inbox, params: params).perform
        expect(telegram_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(telegram_channel.inbox.messages.first.content).to eq('test')
      end
    end

    context 'when group messages' do
      it 'doesnot create conversations, message and contacts' do
        params = {
          'update_id' => 2_342_342_343_242,
          'message' => {
            'message_id' => 1,
            'from' => {
              'id' => 23, 'is_bot' => false, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'language_code' => 'en'
            },
            'chat' => { 'id' => 23, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'type' => 'group' },
            'date' => 1_631_132_077, 'text' => 'test'
          }
        }.with_indifferent_access
        described_class.new(inbox: telegram_channel.inbox, params: params).perform
        expect(telegram_channel.inbox.conversations.count).to eq(0)
      end
    end

    context 'when valid audio messages params' do
      it 'creates appropriate conversations, message and contacts' do
        allow(telegram_channel.inbox.channel).to receive(:get_telegram_file_path).and_return('https://chatwoot-public-assets.s3.amazonaws.com/test-files/rspec/sample.mp3')
        params = {
          'update_id' => 2_342_342_343_242,
          'message' => {
            'message_id' => 1,
            'from' => {
              'id' => 23, 'is_bot' => false, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'language_code' => 'en'
            },
            'chat' => { 'id' => 23, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'type' => 'private' },
            'date' => 1_631_132_077,
            'audio' => {
              'file_id' => 'AwADBAADbXXXXXXXXXXXGBdhD2l6_XX',
              'duration' => 243,
              'mime_type' => 'audio/mpeg',
              'file_size' => 3_897_500,
              'title' => 'Test music file'
            }
          }
        }.with_indifferent_access
        described_class.new(inbox: telegram_channel.inbox, params: params).perform
        expect(telegram_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(telegram_channel.inbox.messages.first.attachments.first.file_type).to eq('audio')
      end
    end

    context 'when valid image attachment params' do
      it 'creates appropriate conversations, message and contacts' do
        allow(telegram_channel.inbox.channel).to receive(:get_telegram_file_path).and_return('https://chatwoot-public-assets.s3.amazonaws.com/test-files/rspec/sample.png')
        params = {
          'update_id' => 2_342_342_343_242,
          'message' => {
            'message_id' => 1,
            'from' => {
              'id' => 23, 'is_bot' => false, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'language_code' => 'en'
            },
            'chat' => { 'id' => 23, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'type' => 'private' },
            'date' => 1_631_132_077,
            'photo' => [{
              'file_id' => 'AgACAgUAAxkBAAODYV3aGZlD6vhzKsE2WNmblsr6zKwAAi-tMRvCoeBWNQ1ENVBzJdwBAAMCAANzAAMhBA',
              'file_unique_id' => 'AQADL60xG8Kh4FZ4', 'file_size' => 1883, 'width' => 90, 'height' => 67
            }]
          }
        }.with_indifferent_access
        described_class.new(inbox: telegram_channel.inbox, params: params).perform
        expect(telegram_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(telegram_channel.inbox.messages.first.attachments.first.file_type).to eq('image')
      end
    end

    context 'when valid sticker attachment params' do
      it 'creates appropriate conversations, message and contacts' do
        allow(telegram_channel.inbox.channel).to receive(:get_telegram_file_path).and_return('https://chatwoot-public-assets.s3.amazonaws.com/test-files/rspec/sample.png')
        params = {
          'update_id' => 2_342_342_343_242,
          'message' => {
            'message_id' => 1,
            'from' => {
              'id' => 23, 'is_bot' => false, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'language_code' => 'en'
            },
            'chat' => { 'id' => 23, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'type' => 'private' },
            'date' => 1_631_132_077,
            'sticker' => {
              'emoji' => '👍', 'width' => 512, 'height' => 512, 'set_name' => 'a834556273_by_HopSins_1_anim', 'is_animated' => 1, 'thumb' => {
                'file_id' => 'AAMCAQADGQEAA0dhXpKorj9CiRpNX3QOn7YPZ6XS4AAC4wADcVG-MexptyOf8SbfAQAHbQADIQQ',
                'file_unique_id' => 'AQAD4wADcVG-MXI', 'file_size' => 4690, 'width' => 128, 'height' => 128
              },
              'file_id' => 'CAACAgEAAxkBAANHYV6SqK4_QokaTV90Dp-2D2el0uAAAuMAA3FRvjHsabcjn_Em3yEE',
              'file_unique_id' => 'AgAD4wADcVG-MQ',
              'file_size' => 7340
            }
          }
        }.with_indifferent_access
        described_class.new(inbox: telegram_channel.inbox, params: params).perform
        expect(telegram_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(telegram_channel.inbox.messages.first.attachments.first.file_type).to eq('image')
      end
    end

    context 'when valid video messages params' do
      it 'creates appropriate conversations, message and contacts' do
        allow(telegram_channel.inbox.channel).to receive(:get_telegram_file_path).and_return('https://chatwoot-public-assets.s3.amazonaws.com/test-files/rspec/sample.mov')
        params = {
          'update_id' => 2_342_342_343_242,
          'message' => {
            'message_id' => 1,
            'from' => {
              'id' => 23, 'is_bot' => false, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'language_code' => 'en'
            },
            'chat' => { 'id' => 23, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'type' => 'private' },
            'date' => 1_631_132_077,
            'video' => {
              'duration' => 1, 'width' => 720, 'height' => 1280, 'file_name' => 'IMG_2170.MOV', 'mime_type' => 'video/mp4', 'thumb' => {
                'file_id' => 'AAMCBQADGQEAA4ZhXd78Xz6_c6gCzbdIkgGiXJcwwwACqwMAAp3x8Fbhf3EWamgCWAEAB20AAyEE', 'file_unique_id' => 'AQADqwMAAp3x8FZy',
                'file_size' => 11_462, 'width' => 180, 'height' => 320
              }, 'file_id' => 'BAACAgUAAxkBAAOGYV3e_F8-v3OoAs23SJIBolyXMMMAAqsDAAKd8fBW4X9xFmpoAlghBA', 'file_unique_id' => 'AgADqwMAAp3x8FY',
              'file_size' => 291_286
            }
          }
        }.with_indifferent_access
        described_class.new(inbox: telegram_channel.inbox, params: params).perform
        expect(telegram_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(telegram_channel.inbox.messages.first.attachments.first.file_type).to eq('video')
      end
    end

    context 'when valid voice attachment params' do
      it 'creates appropriate conversations, message and contacts' do
        allow(telegram_channel.inbox.channel).to receive(:get_telegram_file_path).and_return('https://chatwoot-public-assets.s3.amazonaws.com/test-files/rspec/sample.oga')
        params = {
          'update_id' => 2_342_342_343_242,
          'message' => {
            'message_id' => 1,
            'from' => {
              'id' => 23, 'is_bot' => false, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'language_code' => 'en'
            },
            'chat' => { 'id' => 23, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'type' => 'private' },
            'date' => 1_631_132_077,
            'voice' => {
              'duration' => 2, 'mime_type' => 'audio/ogg', 'file_id' => 'AwACAgUAAxkBAANjYVwnWF_w8LYTchqVdK9dY7mbwYEAAskDAALCoeBWFvS2u4zS6HAhBA',
              'file_unique_id' => 'AgADyQMAAsKh4FY', 'file_size' => 11_833
            }
          }
        }.with_indifferent_access
        described_class.new(inbox: telegram_channel.inbox, params: params).perform
        expect(telegram_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(telegram_channel.inbox.messages.first.attachments.first.file_type).to eq('audio')
      end
    end

    context 'when valid document message params' do
      it 'creates appropriate conversations, message and contacts' do
        allow(telegram_channel.inbox.channel).to receive(:get_telegram_file_path).and_return('https://chatwoot-public-assets.s3.amazonaws.com/test-files/rspec/sample.pdf')
        params = {
          'update_id' => 2_342_342_343_242,
          'message' => {
            'message_id' => 1,
            'from' => {
              'id' => 23, 'is_bot' => false, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'language_code' => 'en'
            },
            'chat' => { 'id' => 23, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'type' => 'private' },
            'date' => 1_631_132_077,
            'document' => {
              'file_id' => 'AwADBAADbXXXXXXXXXXXGBdhD2l6_XX',
              'file_name' => 'Screenshot 2021-09-27 at 2.01.14 PM.png',
              'mime_type' => 'application/png',
              'file_size' => 536_392
            }
          }
        }.with_indifferent_access
        described_class.new(inbox: telegram_channel.inbox, params: params).perform
        expect(telegram_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(telegram_channel.inbox.messages.first.attachments.first.file_type).to eq('file')
      end
    end
  end
end
