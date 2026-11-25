require 'rails_helper'

describe Mail::ResendProvider do
  let(:provider) { described_class.new({}) }
  let(:payloads) { [] }
  let(:pdf_bytes) { "%PDF-1.4\x00\xFF\xFEbinary".b }
  let(:png_bytes) { "\x89PNG\r\n\x1A\n\x00\x01".b }

  around do |example|
    api_key = Resend.api_key
    Resend.api_key = 're_test'
    example.run
  ensure
    Resend.api_key = api_key
  end

  before do
    stub_request(:post, 'https://api.resend.com/emails').to_return do |request|
      payloads << JSON.parse(request.body)
      { status: 200, body: { id: 're_1' }.to_json, headers: { 'Content-Type' => 'application/json' } }
    end
  end

  # Resend takes attachment content as base64; reading it back proves the bytes went out intact.
  def attachment_bytes(payload, filename)
    Base64.strict_decode64(payload['attachments'].find { |a| a['filename'] == filename }['content']).b
  end

  describe '#deliver!' do
    it 'sends an HTML-only message as html and its plain-text rendering' do
      mail = Mail::Message.new(headers: { from: 'Sender <sender@example.com>', to: ['Receiver <receiver@example.com>'], subject: 'Test Email' },
                               body: '<p>This is a test email message.</p>')

      provider.deliver!(mail)

      expect(payloads.sole).to include('from' => 'Sender <sender@example.com>', 'to' => 'Receiver <receiver@example.com>',
                                       'subject' => 'Test Email', 'html' => '<p>This is a test email message.</p>',
                                       'text' => 'This is a test email message.')
      expect(payloads.sole['attachments']).to be_blank
    end

    # A message with an attachment is multipart, and `Mail::Message#decoded` raises on a
    # multipart message, so every reply with a file failed before reaching Resend (#843).
    context 'with a multipart message carrying attachments' do
      let(:mail) do
        pdf = pdf_bytes
        png = png_bytes
        Mail.new do
          from 'Suporte <suporte@example.com>'
          to 'cliente@example.com'
          header['Subject'] = 'Relatório'
          html_part do
            content_type 'text/html; charset=UTF-8'
            body '<p>Olá <b>cliente</b></p>'
          end
          text_part { body 'Olá, cliente (versão em texto)' }
          add_file filename: 'relatório.pdf', content: pdf, mime_type: 'application/pdf'
          add_file filename: 'foto.png', content: png, mime_type: 'image/png'
        end
      end

      it 'sends the html part, the text part and every attachment byte for byte' do
        expect { provider.deliver!(mail) }.not_to raise_error

        payload = payloads.sole
        expect(payload).to include('from' => 'Suporte <suporte@example.com>', 'to' => 'cliente@example.com', 'subject' => 'Relatório',
                                   'text' => 'Olá, cliente (versão em texto)')
        expect(payload['html']).to include('<p>Olá <b>cliente</b></p>')
        expect("#{payload['html']}#{payload['text']}").not_to include('Content-Type:')
        expect(payload['attachments'].pluck('filename')).to contain_exactly('relatório.pdf', 'foto.png')
        expect(attachment_bytes(payload, 'relatório.pdf')).to eq(pdf_bytes)
        expect(attachment_bytes(payload, 'foto.png')).to eq(png_bytes)
      end
    end

    it 'sends a text attachment in its own charset, byte for byte' do
      latin1 = "caf\xE9".b
      mail = Mail.new(from: 'a@example.com', to: 'b@example.com', subject: 's', body: 'x')
      mail.attachments['nota.txt'] = { mime_type: 'text/plain; charset=ISO-8859-1', content: latin1 }

      provider.deliver!(Mail.new(mail.encoded))

      expect(attachment_bytes(payloads.sole, 'nota.txt')).to eq(latin1)
    end

    it 'passes reply-to, cc, bcc and the threading headers on' do
      mail = Mail.new do
        from 'suporte@example.com'
        to 'cliente@example.com'
        cc 'Gerente <gerente@example.com>'
        bcc 'auditoria@example.com'
        reply_to 'reply+abc123@inbound.example.com'
        message_id '<msg-2@example.com>'
        in_reply_to '<msg-1@example.com>'
        references '<msg-0@example.com> <msg-1@example.com>'
        content_type 'text/html; charset=UTF-8'
        body '<p>oi</p>'
      end

      provider.deliver!(mail)

      payload = payloads.sole
      expect(payload).to include('reply_to' => ['reply+abc123@inbound.example.com'], 'cc' => ['Gerente <gerente@example.com>'],
                                 'bcc' => ['auditoria@example.com'])
      expect(payload['headers']).to eq('Message-ID' => '<msg-2@example.com>', 'In-Reply-To' => '<msg-1@example.com>',
                                       'References' => '<msg-0@example.com> <msg-1@example.com>')
    end

    it 'leaves out an address it cannot parse and an empty one, and still sends' do
      mail = Mail.new(from: 'a@example.com', to: 'b@example.com', subject: 's', body: '<p>x</p>',
                      reply_to: 'Agent from Inbox <reply+abc123@>', bcc: '')

      provider.deliver!(mail)

      expect(payloads.sole.keys).not_to include('reply_to', 'bcc')
    end

    # Mail::Message#deliver! reads the delivery method's settings once the email is out.
    it 'delivers through Mail::Message#deliver! without raising after the send' do
      mail = Mail.new(from: 'a@example.com', to: 'b@example.com', subject: 's', body: '<p>x</p>')
      mail.delivery_method(described_class, {})

      expect { mail.deliver! }.not_to raise_error
      expect(payloads.size).to eq(1)
    end

    it 'raises a DeliveryError with the API error message' do
      stub_request(:post, 'https://api.resend.com/emails')
        .to_return(status: 422, body: { statusCode: 422, name: 'validation_error', message: 'attachment too large' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      mail = Mail.new(from: 'a@example.com', to: 'b@example.com', subject: 's', body: '<p>x</p>')

      expect { provider.deliver!(mail) }
        .to raise_error(described_class::DeliveryError, /\AFailed to send email: .*attachment too large/)
    end

    it 'wraps any other failure in a DeliveryError' do
      allow(Resend::Emails).to receive(:send).and_raise(StandardError, 'Connection timed out')
      mail = Mail.new(from: 'a@example.com', to: 'b@example.com', subject: 's', body: '<p>x</p>')

      expect { provider.deliver!(mail) }
        .to raise_error(described_class::DeliveryError, 'An error occurred while sending email: Connection timed out')
    end
  end

  # The path the issue reports: an agent's reply with a file, on an email inbox with no SMTP of
  # its own, on an install that sends through Resend.
  describe 'replying with a file on an email inbox', type: :mailer do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account, channel: create(:channel_email, account: account)) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }
    let(:message) do
      message = create(:message, conversation: conversation, account: account, message_type: 'outgoing', content: 'segue o arquivo')
      attachment = message.attachments.new(account_id: account.id, file_type: :file)
      attachment.file.attach(io: StringIO.new(pdf_bytes), filename: 'contrato.pdf', content_type: 'application/pdf')
      attachment.save!
      message
    end
    let(:mailer) { ConversationReplyMailer.new }

    # The suite's own hooks put :test back after an `around`, so this has to run in `before`.
    before do
      ActionMailer::Base.delivery_method = :resend
      allow(ConversationReplyMailer).to receive(:new).and_return(mailer)
      allow(mailer).to receive(:smtp_config_set_or_development?).and_return(true)
    end

    after { ActionMailer::Base.delivery_method = :test }

    it 'delivers the reply with the file attached' do
      SendReplyJob.perform_now(message.id)

      expect(message.reload.status).not_to eq('failed')
      payload = payloads.sole
      expect(payload['attachments'].pluck('filename')).to eq(['contrato.pdf'])
      expect(attachment_bytes(payload, 'contrato.pdf')).to eq(pdf_bytes)
      expect("#{payload['html']} #{payload['text']}").to include('segue o arquivo')
    end

    it 'marks the reply failed with the API error when Resend refuses it' do
      stub_request(:post, 'https://api.resend.com/emails')
        .to_return(status: 422, body: { statusCode: 422, name: 'validation_error', message: 'attachment too large' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      SendReplyJob.perform_now(message.id)

      expect(message.reload.status).to eq('failed')
      expect(message.external_error).to include('attachment too large')
    end
  end
end
