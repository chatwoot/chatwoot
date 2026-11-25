require 'rails_helper'

RSpec.describe Channel::Telegram do
  let(:telegram_channel) { create(:channel_telegram) }

  # Both calls that set an inbox up run inside the request the operator is waiting on, and
  # a Telegram that accepted the connection and then stopped answering came back as a 500:
  # the app reporting itself broken about the one thing it cannot know. Putting a ceiling
  # on the call without this would only have delivered that 500 sooner, which is the
  # mistake #605 already cost us on the WhatsApp side.
  describe 'when the Bot API does not answer' do
    let(:account) { create(:account) }

    it 'says the check could not be made, instead of failing the request' do
      stub_request(:get, %r{api\.telegram\.org/bot.*/getMe}).to_timeout

      channel = described_class.new(account: account, bot_token: 'a-token')

      expect(channel).not_to be_valid
      expect(channel.errors[:bot_token]).to eq(['could not reach Telegram, try again'])
    end

    # Two different things to do about it: one is fix what you typed, the other is try
    # again. Answering the same for both sends the operator looking for a typo that is
    # not there.
    it 'does not say it the way it says a refused token' do
      stub_request(:get, %r{api\.telegram\.org/bot.*/getMe}).to_return(status: 401, body: '{}')

      channel = described_class.new(account: account, bot_token: 'a-token')

      expect(channel).not_to be_valid
      expect(channel.errors[:bot_token]).to eq(['invalid token'])
    end

    # The webhook is set in `before_save`, where adding an error changes nothing on its
    # own: the record is written anyway, and what gets written is an inbox whose webhook
    # was never set, so it receives no message and nothing on the screen says why. The
    # answer has to roll the save back, and it has to do it as a 422 with the message,
    # since that is the only shape this API renders instead of answering 500.
    it 'saves nothing when the webhook could not be set' do
      stub_request(:get, %r{api\.telegram\.org/bot.*/getMe})
        .to_return(status: 200, body: { result: { username: 'a_bot' } }.to_json)
      stub_request(:post, %r{api\.telegram\.org/bot.*/deleteWebhook}).to_return(status: 200, body: '{}')
      stub_request(:post, %r{api\.telegram\.org/bot.*/setWebhook}).to_timeout

      channel = described_class.new(account: account, bot_token: 'a-token')

      expect { channel.save! }.to raise_error(ActiveRecord::RecordInvalid, /could not reach Telegram/)
      expect(channel).not_to be_persisted
      expect(described_class.where(bot_token: 'a-token')).to be_empty
    end

    # The `rescue` covers the call and not the reading of the answer: a bug in the parsing
    # below reported as "could not reach Telegram" is a bug nobody goes looking for.
    it 'does not answer for a body it did reach and could not read' do
      stub_request(:get, %r{api\.telegram\.org/bot.*/getMe}).to_return(status: 200, body: '{"ok":true}')

      channel = described_class.new(account: account, bot_token: 'a-token')

      expect { channel.valid? }.to raise_error(NoMethodError)
    end
  end

  # A fence, not a checklist. Every call to the Bot API carries one of the two ceilings,
  # and the count is per ceiling so that moving a call between them has to be deliberate.
  # Measured, not remembered: the numbers below come from reading the two files.
  it 'puts every Bot API call under one of the two ceilings' do
    sources = [
      Rails.root.join('app/models/channel/telegram.rb'),
      Rails.root.join('app/services/telegram/send_attachments_service.rb')
    ].map { |path| File.read(path) }.join

    calls = sources.scan(/HTTParty\.\w+/).size

    expect(calls).to eq(7)
    expect(sources.scan('TELEGRAM_SHORT_REQUEST_OPTIONS').size).to eq(5)
    expect(sources.scan('TELEGRAM_REQUEST_OPTIONS').size).to eq(2)
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

    it 'sends raw HTML as escaped text' do
      conversation = create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '123' })
      message = create(:message, message_type: :outgoing, content: "<a>\n<b></b></a>asdf", conversation: conversation)

      stub_request(:post, "https://api.telegram.org/bot#{telegram_channel.bot_token}/sendMessage")
        .with(
          body: "chat_id=123&text=#{
            ERB::Util.url_encode("&lt;a&gt;\n&lt;b&gt;&lt;/b&gt;&lt;/a&gt;asdf")
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
