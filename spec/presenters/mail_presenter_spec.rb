require 'rails_helper'
RSpec.describe MailPresenter do
  include ActionMailbox::TestHelper

  describe 'parsed mail decorator' do
    let(:mail) { create_inbound_email_from_fixture('welcome.eml').mail }
    let(:multiple_in_reply_to_mail) { create_inbound_email_from_fixture('multiple_in_reply_to.eml').mail }
    let(:mail_without_in_reply_to) { create_inbound_email_from_fixture('reply_cc.eml').mail }
    let(:html_mail) { create_inbound_email_from_fixture('welcome_html.eml').mail }
    let(:ascii_mail) { create_inbound_email_from_fixture('non_utf_encoded_mail.eml').mail }
    let(:decorated_mail) { described_class.new(mail) }

    let(:mail_with_no_subject) { create_inbound_email_from_fixture('mail_with_no_subject.eml').mail }
    let(:decorated_mail_with_no_subject) { described_class.new(mail_with_no_subject) }

    it 'give default subject line if mail subject is empty' do
      expect(decorated_mail_with_no_subject.subject).to eq('')
    end

    it 'give utf8 encoded content' do
      expect(decorated_mail.subject).to eq("Discussion: Let's debate these attachments")
      expect(decorated_mail.text_content[:full]).to eq("Let's talk about these images:\n\n")
    end

    it 'give decoded blob attachments' do
      decorated_mail.attachments.each do |attachment|
        expect(attachment.keys).to eq([:original, :blob])
        expect(attachment[:blob].class.name).to eq('ActiveStorage::Blob')
      end
    end

    it 'give number of attachments of the mail' do
      expect(decorated_mail.number_of_attachments).to eq(2)
    end

    it 'give the serialized data of the email to be stored in the message' do
      data = decorated_mail.serialized_data
      expect(data.keys).to eq([
                                :bcc,
                                :cc,
                                :content_type,
                                :date,
                                :from,
                                :headers,
                                :html_content,
                                :in_reply_to,
                                :message_id,
                                :multipart,
                                :number_of_attachments,
                                :references,
                                :subject,
                                :text_content,
                                :to,
                                :auto_reply
                              ])
      expect(data[:content_type]).to include('multipart/alternative')
      expect(data[:date].to_s).to eq('2020-04-20T04:20:20-04:00')
      expect(data[:message_id]).to eq(mail.message_id)
      expect(data[:multipart]).to be(true)
      expect(data[:subject]).to eq(decorated_mail.subject)
      expect(data[:auto_reply]).to eq(decorated_mail.auto_reply?)
    end

    it 'includes forwarded headers in serialized_data' do
      mail_with_headers = Mail.new do
        from 'Sender <sender@example.com>'
        to 'Inbox <inbox@example.com>'
        subject :header
        body 'Hi'
        header['X-Original-From'] = 'Original <original@example.com>'
        header['X-Original-Sender'] = 'original@example.com'
        header['X-Forwarded-For'] = 'forwarder@example.com'
      end

      data = described_class.new(mail_with_headers).serialized_data

      expect(data[:headers]).to eq(
        'x-original-from' => 'Original <original@example.com>',
        'x-original-sender' => 'original@example.com',
        'x-forwarded-for' => 'forwarder@example.com'
      )
    end

    it 'returns nil headers when forwarding headers are missing' do
      mail_without_headers = Mail.new do
        from 'Sender <sender@example.com>'
        to 'Inbox <inbox@example.com>'
        subject :header
        body 'Hi'
      end

      data = described_class.new(mail_without_headers).serialized_data

      expect(data[:headers]).to be_nil
    end

    it 'give email from in downcased format' do
      expect(decorated_mail.from.first.eql?(mail.from.first.downcase)).to be true
    end

    describe '#from' do
      let(:mail_with_sender) { Mail.new { from 'Sender <SENDER@EXAMPLE.COM>' } }

      it 'drops blank reply-to entries and keeps valid reply-to addresses' do
        allow(mail_with_sender).to receive(:reply_to).and_return([nil, '', 'REPLY@EXAMPLE.COM'])

        expect(described_class.new(mail_with_sender).from).to eq(['reply@example.com'])
      end

      it 'falls back to from when reply-to has no usable addresses' do
        allow(mail_with_sender).to receive(:reply_to).and_return([nil, ''])

        expect(described_class.new(mail_with_sender).from).to eq(['sender@example.com'])
      end

      it 'drops blank entries from the from list' do
        allow(mail_with_sender).to receive(:reply_to).and_return(nil)
        allow(mail_with_sender).to receive(:from).and_return([nil, '', 'SENDER@EXAMPLE.COM'])

        expect(described_class.new(mail_with_sender).from).to eq(['sender@example.com'])
      end

      it 'returns no addresses when both lists lack a sender' do
        empty_mail = Mail.new
        allow(empty_mail).to receive(:reply_to).and_return([nil, ''])
        allow(empty_mail).to receive(:from).and_return([nil, ''])

        expect(described_class.new(empty_mail).from).to eq([])
      end
    end

    it 'parse html content in the mail' do
      decorated_html_mail = described_class.new(html_mail)
      expect(decorated_html_mail.subject).to eq('Fwd: How good are you in English? How did you improve your English?')
      expect(decorated_html_mail.text_content[:reply][0..70]).to eq(
        "I'm learning English as a first language for the past 13 years, but to "
      )
    end

    it 'encodes email to UTF-8' do
      decorated_html_mail = described_class.new(ascii_mail)
      expect(decorated_html_mail.subject).to eq('أهلين عميلنا الكريم ')
      expect(decorated_html_mail.text_content[:reply][0..70]).to eq(
        'أنظروا، أنا أحتاجها فقط لتقوم بالتدقيق في مقالتي الشخصية'
      )
    end

    describe '#in_reply_to' do
      context 'when "in_reply_to" is an array' do
        it 'returns the first value from the array' do
          mail_presenter = described_class.new(multiple_in_reply_to_mail)
          expect(mail_presenter.in_reply_to).to eq('4e6e35f5a38b4_479f13bb90078171@small-app-01.mail')
        end
      end

      context 'when "in_reply_to" is not an array' do
        it 'returns the value as is' do
          mail_presenter = described_class.new(mail)
          expect(mail_presenter.in_reply_to).to eq('4e6e35f5a38b4_479f13bb90078178@small-app-01.mail')
        end
      end

      context 'when "in_reply_to" is blank' do
        it 'returns nil' do
          mail_presenter = described_class.new(mail_without_in_reply_to)
          expect(mail_presenter.in_reply_to).to be_nil
        end
      end
    end

    describe '#references' do
      let(:references_mail) { create_inbound_email_from_fixture('references.eml').mail }
      let(:mail_presenter_with_references) { described_class.new(references_mail) }

      context 'when mail has references' do
        it 'returns an array of reference IDs' do
          expect(mail_presenter_with_references.references).to eq(['4e6e35f5a38b4_479f13bb90078178@small-app-01.mail', 'test-reference-id'])
        end
      end

      context 'when mail has no references' do
        it 'returns an empty array' do
          mail_presenter = described_class.new(mail_without_in_reply_to)
          expect(mail_presenter.references).to eq([])
        end
      end

      context 'when references are included in serialized_data' do
        it 'includes references in the serialized data' do
          data = mail_presenter_with_references.serialized_data
          expect(data[:references]).to eq(['4e6e35f5a38b4_479f13bb90078178@small-app-01.mail', 'test-reference-id'])
        end
      end
    end

    describe 'auto_reply?' do
      let(:auto_reply_mail) { create_inbound_email_from_fixture('auto_reply.eml').mail }
      let(:auto_reply_with_auto_submitted_mail) { create_inbound_email_from_fixture('auto_reply_with_auto_submitted.eml').mail }
      let(:decorated_auto_reply_mail) { described_class.new(auto_reply_mail) }
      let(:decorated_auto_reply_with_auto_submitted_mail) { described_class.new(auto_reply_with_auto_submitted_mail) }

      it 'returns true for auto-reply emails' do
        expect(decorated_auto_reply_mail.auto_reply?).to be true
        expect(decorated_auto_reply_with_auto_submitted_mail.auto_reply?).to be true
      end

      it 'includes auto_reply status in serialized_data' do
        expect(decorated_auto_reply_mail.serialized_data[:auto_reply]).to be true
        expect(decorated_mail.serialized_data[:auto_reply]).to be_falsey
      end
    end

    describe 'malformed sender headers' do
      let(:mail_with_malformed_from) do
        Mail.new do
          header['From'] = 'Kevin McDonald <info@example.com'
          to 'Inbox <inbox@example.com>'
          subject :header
          body 'Hi'
        end
      end

      let(:mail_with_malformed_reply_to) do
        Mail.new do
          from 'Sender <sender@example.com>'
          to 'Inbox <inbox@example.com>'
          subject :header
          body 'Hi'
          header['Reply-To'] = 'Reply User <reply@example.com'
        end
      end

      let(:mail_with_original_sender_header) do
        Mail.new do
          from 'Sender <sender@example.com>'
          to 'Inbox <inbox@example.com>'
          subject :header
          body 'Hi'
          header['Reply-To'] = 'Reply User <reply@example.com'
          header['X-Original-Sender'] = 'Forwarded Sender <forwarded.sender@example.com>'
        end
      end

      let(:mail_with_invalid_original_sender_header) do
        Mail.new do
          from 'Sender <sender@example.com>'
          to 'Inbox <inbox@example.com>'
          subject :header
          body 'Hi'
          header['Reply-To'] = 'Reply User <reply@example.com'
          header['X-Original-Sender'] = 'not an email address'
        end
      end

      it 'returns nil sender values when from header is malformed' do
        presenter = described_class.new(mail_with_malformed_from)

        expect(presenter.original_sender).to be_nil
        expect(presenter.sender_name).to be_nil
        expect(presenter.notification_email_from_chatwoot?).to be(false)
      end

      it 'falls back to from header when reply_to is malformed' do
        presenter = described_class.new(mail_with_malformed_reply_to)
        expect(presenter.original_sender).to eq('sender@example.com')
      end

      it 'uses parsed X-Original-Sender value when available' do
        presenter = described_class.new(mail_with_original_sender_header)
        expect(presenter.original_sender).to eq('forwarded.sender@example.com')
      end

      it 'falls back to from when X-Original-Sender is invalid' do
        presenter = described_class.new(mail_with_invalid_original_sender_header)
        expect(presenter.original_sender).to eq('sender@example.com')
      end

      it 'matches notification sender emails case-insensitively' do
        mail_with_uppercase_sender = Mail.new do
          from 'Chatwoot <ACCOUNTS@CHATWOOT.COM>'
          to 'Inbox <inbox@example.com>'
          subject :header
          body 'Hi'
        end

        with_modified_env MAILER_SENDER_EMAIL: 'Chatwoot <accounts@chatwoot.com>' do
          presenter = described_class.new(mail_with_uppercase_sender)
          expect(presenter.notification_email_from_chatwoot?).to be(true)
        end
      end
    end
  end

  # iOS Mail composes a `multipart/alternative` whose one child is a `multipart/mixed`: a
  # stub that renders to nothing, then the attachment, then the part the customer wrote.
  # The mail gem answers `html_part` with the first `text/html` it meets, so the message
  # reached the agent as an empty bubble under a subject.
  describe 'a message whose first html part is a stub' do
    def nested(first_html, second_html)
      inner = Mail::Part.new
      inner.content_type = 'multipart/mixed'
      [first_html, second_html].each do |html|
        part = Mail::Part.new
        part.content_type = 'text/html; charset=utf-8'
        part.body = html
        inner.add_part(part)
      end
      mail = Mail.new(from: 'cliente@example.com', to: 'sac@example.com', subject: 'Pedido')
      mail.content_type = 'multipart/alternative'
      mail.add_part(inner)
      mail
    end

    let(:stub_html) { '<html><body dir="auto"><br></body></html>' }
    let(:real_html) { '<html><body>Bom dia, preciso cancelar o pedido e receber o estorno.</body></html>' }

    it 'reads the part that carries the message instead of the stub above it' do
      presenter = described_class.new(nested(stub_html, real_html))
      expect(presenter.html_content[:full]).to include('preciso cancelar o pedido')
    end

    # The restraint is the point. Taking the largest outright would prefer a quoted forward
    # over the short reply written above it, which is a worse failure and a commoner shape.
    it 'leaves a first part that says something alone, however short' do
      presenter = described_class.new(nested('<html><body>Ok, obrigado.</body></html>', real_html))
      expect(presenter.html_content[:full]).to include('Ok, obrigado.')
    end

    it 'still answers nothing when no part says anything' do
      presenter = described_class.new(nested(stub_html, '<html><body><br></body></html>'))
      expect(presenter.html_content).to eq({})
    end

    # An attached document has parts of its own, and `attachment?` does not answer where the
    # message stops: it is a question about a file, and the container holding an attached
    # document has no filename, so it answers false while everything under it is attached.
    it 'does not take the body out of an attached document' do
      mail = nested(stub_html, '<html><body>Segue em anexo.</body></html>')
      attached = Mail::Part.new
      attached.content_type = 'multipart/related'
      attached.content_disposition = 'attachment'
      inner = Mail::Part.new
      inner.content_type = 'text/html; charset=utf-8'
      inner.body = "<html><body>#{'Texto de uma nota fiscal encaminhada. ' * 40}</body></html>"
      attached.add_part(inner)
      mail.parts.first.add_part(attached)

      expect(described_class.new(mail).html_content[:full]).to include('Segue em anexo.')
    end

    # Scoring a part means rendering it, and rendering it means decoding it the way the
    # reader will. `body.decoded` stops at the transfer encoding and hands back bytes
    # tagged binary, which on UTF-16 parse to nothing: the part that says something scores
    # zero and loses to a one-word rival.
    it 'reads a part in a charset a byte does not fit' do
      written = '<html><body>Preciso do reembolso, o evento foi cancelado.</body></html>'
      payload = [written.encode('UTF-16LE').force_encoding('BINARY')].pack('m0')
      raw = +"From: cliente@example.com\r\nTo: sac@example.com\r\nSubject: Reembolso\r\n"
      raw << "MIME-Version: 1.0\r\nContent-Type: multipart/alternative; boundary=\"B\"\r\n\r\n"
      raw << "--B\r\nContent-Type: text/html; charset=UTF-16LE\r\n"
      raw << "Content-Transfer-Encoding: base64\r\n\r\n#{payload}\r\n"
      raw << "--B\r\nContent-Type: text/html; charset=utf-8\r\n\r\n<html><body>ok</body></html>\r\n--B--\r\n"

      presenter = described_class.new(Mail.read_from_string(raw))

      expect(presenter.html_content[:full]).to include('Preciso do reembolso')
    end

    # A `multipart/related` carries one body and a set of resources it points at by
    # `Content-ID`. A `text/html` resource is not a candidate, however long it is, and the
    # gem only avoids it by accident of ordering: it answers with the first part it meets,
    # and the root comes first.
    it 'does not take the body from a resource the body points at' do
      raw = +"From: cliente@example.com\r\nTo: sac@example.com\r\nSubject: Pedido\r\n"
      raw << "MIME-Version: 1.0\r\nContent-Type: multipart/alternative; boundary=\"A\"\r\n\r\n"
      raw << "--A\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n\r\n"
      raw << "--A\r\nContent-Type: multipart/related; boundary=\"R\"; start=\"<raiz@ex>\"\r\n\r\n"
      raw << "--R\r\nContent-Type: text/html; charset=utf-8\r\nContent-ID: <raiz@ex>\r\n\r\n"
      raw << "<html><body><br></body></html>\r\n"
      raw << "--R\r\nContent-Type: text/html; charset=utf-8\r\nContent-ID: <recurso@ex>\r\n\r\n"
      raw << "<html><body>#{'Rodape institucional da empresa. ' * 20}</body></html>\r\n--R--\r\n--A--\r\n"

      chosen = HtmlPartChooser.for(Mail.read_from_string(raw))

      expect(chosen.content_id).to eq('<raiz@ex>')
    end

    # This sits on every inbound email and `html_content` asks for it twice, so the parse
    # has to be reached only by a message that actually carries rival parts.
    it 'does not parse anything to answer a message with one html part' do
      mail = Mail.new(from: 'cliente@example.com', to: 'sac@example.com', subject: 'Oi')
      mail.content_type = 'multipart/alternative'
      text = Mail::Part.new
      text.content_type = 'text/plain; charset=utf-8'
      text.body = 'Bom dia'
      html = Mail::Part.new
      html.content_type = 'text/html; charset=utf-8'
      html.body = '<html><body>Bom dia</body></html>'
      [text, html].each { |part| mail.add_part(part) }

      presenter = described_class.new(mail)
      allow(HtmlParser).to receive(:parse_reply).and_call_original
      presenter.html_part
      presenter.html_part

      expect(HtmlParser).not_to have_received(:parse_reply)
    end
  end
end
