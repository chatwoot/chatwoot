# encoding: utf-8
require 'spec_helper'

describe LetterOpener::Message do
  let(:location) { File.expand_path('../../../tmp/letter_opener', __FILE__) }

  def mail(options={}, &blk)
    Mail.new(options, &blk)
  end

  describe '#reply_to' do
    it 'handles one email as a string' do
      mail    = mail(:reply_to => 'test@example.com')
      message = described_class.new(mail, location: location)
      expect(message.reply_to).to eq('test@example.com')
    end

    it 'handles one email with display names' do
      mail    = mail(:reply_to => 'test <test@example.com>')
      message = described_class.new(mail, location: location)
      expect(message.reply_to).to eq('test <test@example.com>')
    end

    it 'handles array of emails' do
      mail    = mail(:reply_to => ['test1@example.com', 'test2@example.com'])
      message = described_class.new(mail, location: location)
      expect(message.reply_to).to eq('test1@example.com, test2@example.com')
    end

    it 'handles array of emails with display names' do
      mail    = mail(:reply_to => ['test1 <test1@example.com>', 'test2 <test2@example.com>'])
      message = described_class.new(mail, location: location)
      expect(message.reply_to).to eq('test1 <test1@example.com>, test2 <test2@example.com>')
    end

  end

  describe '#subject' do
    it 'handles UTF-8 charset subject' do
      mail = mail(:subject => 'test_mail')
      message = described_class.new(mail, location: location)
      expect(message.subject).to eq('test_mail')
    end

    it 'handles encode ISO-2022-JP charset subject' do
      mail = mail(:subject => '=?iso-2022-jp?B?GyRCJUYlOSVIJWEhPCVrGyhC?=')
      message = described_class.new(mail, location: location)
      expect(message.subject).to eq('テストメール')
    end
  end

  describe '#to' do
    it 'handles one email as a string' do
      mail   = mail(:to => 'test@example.com')
      message = described_class.new(mail, location: location)
      expect(message.to).to eq('test@example.com')
    end

    it 'handles one email with display names' do
      mail    = mail(:to => 'test <test@example.com>')
      message = described_class.new(mail, location: location)
      expect(message.to).to eq('test <test@example.com>')
    end

    it 'handles array of emails' do
      mail    = mail(:to => ['test1@example.com', 'test2@example.com'])
      message = described_class.new(mail, location: location)
      expect(message.to).to eq('test1@example.com, test2@example.com')
    end

    it 'handles array of emails with display names' do
      mail    = mail(:to => ['test1 <test1@example.com>', 'test2 <test2@example.com>'])
      message = described_class.new(mail, location: location)
      expect(message.to).to eq('test1 <test1@example.com>, test2 <test2@example.com>')
    end

  end

  describe '#cc' do
    it 'handles one cc email as a string' do
      mail    = mail(:cc => 'test@example.com')
      message = described_class.new(mail, location: location)
      expect(message.cc).to eq('test@example.com')
    end

    it 'handles one cc email with display name' do
      mail    = mail(:cc => ['test <test1@example.com>', 'test2 <test2@example.com>'])
      message = described_class.new(mail, location: location)
      expect(message.cc).to eq('test <test1@example.com>, test2 <test2@example.com>')
    end

    it 'handles array of cc emails' do
      mail    = mail(:cc => ['test1@example.com', 'test2@example.com'])
      message = described_class.new(mail, location: location)
      expect(message.cc).to eq('test1@example.com, test2@example.com')
    end

    it 'handles array of cc emails with display names' do
      mail    = mail(:cc => ['test <test1@example.com>', 'test2 <test2@example.com>'])
      message = described_class.new(mail, location: location)
      expect(message.cc).to eq('test <test1@example.com>, test2 <test2@example.com>')
    end

  end

  describe '#bcc' do
    it 'handles one bcc email as a string' do
      mail    = mail(:bcc => 'test@example.com')
      message = described_class.new(mail, location: location)
      expect(message.bcc).to eq('test@example.com')
    end

    it 'handles one bcc email with display name' do
      mail    = mail(:bcc => ['test <test1@example.com>', 'test2 <test2@example.com>'])
      message = described_class.new(mail, location: location)
      expect(message.bcc).to eq('test <test1@example.com>, test2 <test2@example.com>')
    end

    it 'handles array of bcc emails' do
      mail    = mail(:bcc => ['test1@example.com', 'test2@example.com'])
      message = described_class.new(mail, location: location)
      expect(message.bcc).to eq('test1@example.com, test2@example.com')
    end

    it 'handles array of bcc emails with display names' do
      mail    = mail(:bcc => ['test <test1@example.com>', 'test2 <test2@example.com>'])
      message = described_class.new(mail, location: location)
      expect(message.bcc).to eq('test <test1@example.com>, test2 <test2@example.com>')
    end

  end

  describe '#sender' do
    it 'handles one email as a string' do
      mail    = mail(:sender => 'sender@example.com')
      message = described_class.new(mail, location: location)
      expect(message.sender).to eq('sender@example.com')
    end

    it 'handles one email as a string with display name' do
      mail    = mail(:sender => 'test <test@example.com>')
      message = described_class.new(mail, location: location)
      expect(message.sender).to eq('test <test@example.com>')
    end

    it 'handles array of emails' do
      mail    = mail(:sender => ['sender1@example.com', 'sender2@example.com'])
      message = described_class.new(mail, location: location)
      expect(message.sender).to eq('sender1@example.com, sender2@example.com')
    end

    it 'handles array of emails with display names' do
      mail    = mail(:sender => ['test <test1@example.com>', 'test2 <test2@example.com>'])
      message = described_class.new(mail, location: location)
      expect(message.sender).to eq('test <test1@example.com>, test2 <test2@example.com>')
    end

  end

  describe '#<=>' do
    it 'sorts rich type before plain type' do
      plain = described_class.new(double(content_type: 'text/plain'), location: location)
      rich  = described_class.new(double(content_type: 'text/html'), location: location)
      expect([plain, rich].sort).to eq([rich, plain])
    end
  end

  describe '#auto_link' do
    let(:message){ described_class.new(mail, location: location) }

    it 'does not modify unlinkable text' do
      text = 'the quick brown fox jumped over the lazy dog'
      expect(message.auto_link(text)).to eq(text)
    end

    it 'adds links for http' do
      raw = "Link to http://localhost:3000/example/path path"
      linked = "Link to <a href=\"http://localhost:3000/example/path\">http://localhost:3000/example/path</a> path"
      expect(message.auto_link(raw)).to eq(linked)
    end
  end

  describe '#body' do
    it 'handles UTF-8 charset body correctly, with QP CTE, for a non-multipart message' do
      mail = mail(:sender => 'sender@example.com') do
        content_type "text/html; charset=UTF-8"
        content_transfer_encoding 'quoted-printable'
        body "☃"
      end
      message = message = described_class.new(mail, location: location)
      expect(message.body.encoding.name).to eq('UTF-8')
    end

    it 'handles UTF-8 charset HTML part body correctly, with QP CTE, for a multipart message' do
      mail = mail(:sender => 'sender@example.com') do
        html_part do
          content_type "text/html; charset=UTF-8"
          content_transfer_encoding 'quoted-printable'
          body "☃"
        end
      end
      message = described_class.new(mail, location: location, part: mail.html_part)
      expect(message.body.encoding.name).to eq('UTF-8')
    end

    it 'handles UTF-8 charset text part body correctly, with QP CTE, for a multipart message' do
      mail = mail(:sender => 'sender@example.com') do
        text_part do
          content_type "text/plain; charset=UTF-8"
          content_transfer_encoding 'quoted-printable'
          body "☃"
        end
      end
      message = described_class.new(mail, location: location, part: mail.text_part)
      expect(message.body.encoding.name).to eq('UTF-8')
    end
  end

  describe '#render' do
    it 'records the saved email path for plain content type' do
      mail = mail(:subject => 'test_mail')
      message = described_class.new(mail, location: location)
      message.render
      expect(mail['location_plain'].value).to end_with('tmp/letter_opener/plain.html')
    end


    it 'records the saved email path for rich content type' do
      mail = mail(:content_type => 'text/html', :subject => 'test_mail')
      message = described_class.new(mail, location: location)
      message.render
      expect(mail['location_rich'].value).to end_with('tmp/letter_opener/rich.html')
    end
  end

  describe '.rendered_messages' do
    it 'uses configured default template if options not given' do
      allow(LetterOpener.configuration).to receive(:location) { location }
      messages = described_class.rendered_messages(mail)
      expect(messages.first.template).not_to be_nil
    end

    it 'fails if necessary defaults are not provided' do
      allow(LetterOpener.configuration).to receive(:location) { nil }
      expect { described_class.rendered_messages(mail) }.to raise_error(ArgumentError)
    end

    it 'fails if necessary defaults are not provided' do
      allow(LetterOpener.configuration).to receive(:message_template) { nil }
      expect { described_class.rendered_messages(mail) }.to raise_error(ArgumentError)
    end
  end
end
