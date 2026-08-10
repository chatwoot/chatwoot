require 'rails_helper'

RSpec.describe Channel::Telegram do
  let(:telegram_channel) { create(:channel_telegram) }

  describe 'bot validation' do
    it 'stores Telegram Business capability details from getMe' do
      channel = build(:channel_telegram, account: create(:account), bot_token: 'business-capable-token', business_config_error: 'Old error')
      stub_request(:get, 'https://api.telegram.org/botbusiness-capable-token/getMe').to_return(
        status: 200,
        body: { ok: true, result: { username: 'business_bot', can_connect_to_business: true } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

      travel_to(Time.zone.parse('2026-08-10 10:00:00')) do
        expect(channel).to be_valid
        expect(channel.bot_name).to eq('business_bot')
        expect(channel.business_config).to eq('can_connect_to_business' => true, 'connections' => {})
        expect(channel.business_config_checked_at).to eq(Time.current)
        expect(channel.business_config_error).to be_nil
      end
    end

    it 'refreshes capability and clears connection state when the bot token changes' do
      channel = create(
        :channel_telegram,
        business_config: {
          'can_connect_to_business' => true,
          'connections' => { 'old-connection' => { 'is_enabled' => true, 'rights' => { 'can_reply' => true } } }
        },
        business_config_error: 'Old error'
      )
      channel = described_class.find(channel.id)
      allow(channel).to receive(:setup_telegram_webhook)
      stub_request(:get, 'https://api.telegram.org/botreplacement-token/getMe').to_return(
        status: 200,
        body: { ok: true, result: { username: 'replacement_bot', can_connect_to_business: false } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

      travel_to(Time.zone.parse('2026-08-10 11:00:00')) do
        channel.update!(bot_token: 'replacement-token')

        expect(channel.bot_name).to eq('replacement_bot')
        expect(channel.business_config).to eq('can_connect_to_business' => false, 'connections' => {})
        expect(channel.business_config_checked_at).to eq(Time.current)
        expect(channel.business_config_error).to be_nil
      end
    end
  end

  describe '#refresh_business_config!' do
    it 'records an error when Telegram cannot return the bot information' do
      channel = described_class.find(telegram_channel.id)
      stub_request(:get, "https://api.telegram.org/bot#{channel.bot_token}/getMe").to_return(
        status: 401,
        body: { ok: false, description: 'Unauthorized' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

      travel_to(Time.zone.parse('2026-08-10 12:00:00')) do
        expect(channel.refresh_business_config!).to be(false)
        expect(channel.business_config_checked_at).to eq(Time.current)
        expect(channel.business_config_error).to eq('Unauthorized')
      end
    end

    it 'does not apply a response fetched with a token that has since changed' do
      checked_at = 1.day.ago
      channel = create(
        :channel_telegram,
        bot_name: 'current_bot',
        business_config: { 'can_connect_to_business' => false, 'connections' => {} },
        business_config_checked_at: checked_at
      )
      channel = described_class.find(channel.id)
      stub_request(:get, "https://api.telegram.org/bot#{channel.bot_token}/getMe").to_return do
        # Simulate a completed token rotation while the old getMe request is in flight.
        # rubocop:disable Rails/SkipsModelValidations
        described_class.find(channel.id).update_columns(bot_token: 'replacement-token', bot_name: 'replacement_bot')
        # rubocop:enable Rails/SkipsModelValidations
        {
          status: 200,
          body: { ok: true, result: { username: 'stale_bot', can_connect_to_business: true } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        }
      end

      expect(channel.refresh_business_config!).to be(false)
      expect(channel.reload.bot_name).to eq('replacement_bot')
      expect(channel.business_config).to eq('can_connect_to_business' => false, 'connections' => {})
      expect(channel.business_config_checked_at).to be_within(1.second).of(checked_at)
    end

    it 'preserves the error when multiple active connections remain after refresh' do
      channel = create(
        :channel_telegram,
        business_config: {
          'can_connect_to_business' => true,
          'connections' => {
            'connection-1' => { 'is_enabled' => true },
            'connection-2' => { 'is_enabled' => true }
          }
        },
        business_config_error: described_class::MULTIPLE_ACTIVE_CONNECTIONS_ERROR
      )
      channel = described_class.find(channel.id)
      stub_request(:get, "https://api.telegram.org/bot#{channel.bot_token}/getMe").to_return(
        status: 200,
        body: { ok: true, result: { username: 'business_bot', can_connect_to_business: true } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

      expect(channel.refresh_business_config!).to be(true)
      expect(channel.business_config_error).to eq(described_class::MULTIPLE_ACTIVE_CONNECTIONS_ERROR)
    end
  end

  describe '#convert_markdown_to_telegram_html' do
    subject { telegram_channel.send(:convert_markdown_to_telegram_html, text) }

    context 'when text contains multiple newline characters' do
      let(:text) { "Line one\nLine two\n\nLine four" }

      it 'preserves multiple newline characters' do
        expect(subject).to eq("Line one\nLine two\n\nLine four")
      end
    end

    context 'when text contains broken markdown' do
      let(:text) { 'This is a **broken markdown with <b>HTML</b> tags.' }

      it 'does not break and properly converts to Telegram HTML format and escapes html tags' do
        expect(subject).to eq('This is a **broken markdown with &lt;b&gt;HTML&lt;/b&gt; tags.')
      end
    end

    context 'when text contains markdown and HTML elements' do
      let(:text) { "Hello *world*! This is <b>bold</b> and this is <i>italic</i>.\nThis is a new line." }

      it 'converts markdown to Telegram HTML format and escapes other html' do
        expect(subject).to eq("Hello <em>world</em>! This is &lt;b&gt;bold&lt;/b&gt; and this is &lt;i&gt;italic&lt;/i&gt;.\nThis is a new line.")
      end
    end

    context 'when text contains unsupported HTML tags' do
      let(:text) { 'This is a <span>test</span> with unsupported tags.' }

      it 'removes unsupported HTML tags' do
        expect(subject).to eq('This is a &lt;span&gt;test&lt;/span&gt; with unsupported tags.')
      end
    end

    context 'when text contains special characters' do
      let(:text) { 'Special characters: & < >' }

      it 'escapes special characters' do
        expect(subject).to eq('Special characters: &amp; &lt; &gt;')
      end
    end

    context 'when text contains markdown links' do
      let(:text) { 'Check this [link](http://example.com) out!' }

      it 'converts markdown links to Telegram HTML format' do
        expect(subject).to eq('Check this <a href="http://example.com">link</a> out!')
      end
    end
  end

  context 'when a valid message and empty attachments' do
    it 'send message' do
      message = create(:message, message_type: :outgoing, content: 'test',
                                 conversation: create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '123' }))

      stub_request(:post, "https://api.telegram.org/bot#{telegram_channel.bot_token}/sendMessage")
        .with(
          body: 'chat_id=123&text=test&reply_markup=&parse_mode=HTML&reply_to_message_id='
        )
        .to_return(
          status: 200,
          body: { result: { message_id: 'telegram_123' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(telegram_channel.send_message_on_telegram(message)).to eq('telegram_123')
    end

    it 'send message with markdown converted to telegram HTML' do
      message = create(:message, message_type: :outgoing, content: '**test** *test* ~test~',
                                 conversation: create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '123' }))

      stub_request(:post, "https://api.telegram.org/bot#{telegram_channel.bot_token}/sendMessage")
        .with(
          body: "chat_id=123&text=#{
            ERB::Util.url_encode('<strong>test</strong> <em>test</em> ~test~')
          }&reply_markup=&parse_mode=HTML&reply_to_message_id="
        )
        .to_return(
          status: 200,
          body: { result: { message_id: 'telegram_123' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(telegram_channel.send_message_on_telegram(message)).to eq('telegram_123')
    end

    it 'send message with reply_markup' do
      message = create(
        :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                  content_attributes: { 'items' => [{ 'title' => 'test', 'value' => 'test' }] },
                  conversation: create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '123' })
      )

      stub_request(:post, "https://api.telegram.org/bot#{telegram_channel.bot_token}/sendMessage")
        .with(
          body: 'chat_id=123&text=test' \
                '&reply_markup=%7B%22one_time_keyboard%22%3Atrue%2C%22inline_keyboard%22%3A%5B%5B%7B%22text%22%3A%22test%22%2C%22' \
                'callback_data%22%3A%22test%22%7D%5D%5D%7D&parse_mode=HTML&reply_to_message_id='
        )
        .to_return(
          status: 200,
          body: { result: { message_id: 'telegram_123' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(telegram_channel.send_message_on_telegram(message)).to eq('telegram_123')
    end

    it 'sends message with business_connection_id' do
      additional_attributes = { 'chat_id' => '123', 'business_connection_id' => 'eooW3KF5WB5HxTD7T826' }
      message = create(:message, message_type: :outgoing, content: 'test',
                                 conversation: create(:conversation, inbox: telegram_channel.inbox, additional_attributes: additional_attributes))

      stub_request(:post, "https://api.telegram.org/bot#{telegram_channel.bot_token}/sendMessage")
        .with(
          body: 'chat_id=123&text=test&reply_markup=&parse_mode=HTML&reply_to_message_id=&business_connection_id=eooW3KF5WB5HxTD7T826'
        )
        .to_return(
          status: 200,
          body: { result: { message_id: 'telegram_123' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(telegram_channel.send_message_on_telegram(message)).to eq('telegram_123')
    end

    it 'send text message failed' do
      message = create(:message, message_type: :outgoing, content: 'test',
                                 conversation: create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '123' }))

      stub_request(:post, "https://api.telegram.org/bot#{telegram_channel.bot_token}/sendMessage")
        .with(
          body: 'chat_id=123&text=test&reply_markup=&parse_mode=HTML&reply_to_message_id='
        )
        .to_return(
          status: 403,
          headers: { 'Content-Type' => 'application/json' },
          body: {
            ok: false,
            error_code: '403',
            description: 'Forbidden: bot was blocked by the user'
          }.to_json
        )
      telegram_channel.send_message_on_telegram(message)
      expect(message.reload.status).to eq('failed')
      expect(message.reload.external_error).to eq('403, Forbidden: bot was blocked by the user')
    end
  end

  context 'when message contains attachments' do
    let(:message) do
      create(:message, message_type: :outgoing, content: nil,
                       conversation: create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '123' }))
    end

    it 'calls send attachment service' do
      telegram_attachment_service = double
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')

      allow(Telegram::SendAttachmentsService).to receive(:new).with(message: message).and_return(telegram_attachment_service)
      allow(telegram_attachment_service).to receive(:perform).and_return('telegram_456')
      expect(telegram_channel.send_message_on_telegram(message)).to eq('telegram_456')
    end
  end
end
