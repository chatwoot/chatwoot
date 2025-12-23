require "spec_helper"

describe LetterOpener::DeliveryMethod do
  let(:location)        { File.expand_path('../../../tmp/letter_opener', __FILE__) }
  let(:file_uri_scheme) { nil }

  let(:plain_file) { Dir["#{location}/*/plain.html"].first }
  let(:plain)      { CGI.unescape_html(File.read(plain_file)) }

  before do
    allow(Launchy).to receive(:open)
    FileUtils.rm_rf(location)
    context = self

    Mail.defaults do
      delivery_method LetterOpener::DeliveryMethod, location: context.location, file_uri_scheme: context.file_uri_scheme
    end
  end

  it 'raises an exception if no location passed' do
    expect { LetterOpener::DeliveryMethod.new }.to raise_exception(LetterOpener::DeliveryMethod::InvalidOption)
    expect { LetterOpener::DeliveryMethod.new(location: "foo") }.to_not raise_exception
  end

  context 'integration' do
    before do
      expect(Launchy).to receive(:open).and_call_original
      ENV['LAUNCHY_DRY_RUN'] = 'true'
    end

    context 'normal location path' do
      it 'opens email' do
        expect($stdout).to receive(:puts)
        expect {
          Mail.deliver do
            to   'Bar bar@example.com'
            from 'Foo foo@example.com'
            body 'World! http://example.com'
          end
        }.not_to raise_error
      end
    end

    context 'with spaces in location path' do
      let(:location) { File.expand_path('../../../tmp/letter_opener with space', __FILE__) }

      it 'opens email' do
        expect($stdout).to receive(:puts)
        expect {
          Mail.deliver do
            to   'Bar bar@example.com'
            from 'Foo foo@example.com'
            body 'World! http://example.com'
          end
        }.not_to raise_error
      end
    end
  end

  context 'content' do
    context 'plain' do
      before do
        expect(Launchy).to receive(:open)

        Mail.deliver do
          from     'Foo <foo@example.com>'
          sender   'Baz <baz@example.com>'
          reply_to 'No Reply <no-reply@example.com>'
          to       'Bar <bar@example.com>'
          cc       'Qux <qux@example.com>'
          bcc      'Qux <qux@example.com>'
          subject  'Hello'
          body     'World! http://example.com'
        end
      end

      it 'creates plain html document' do
        expect(File.exist?(plain_file)).to be_truthy
      end

      it 'saves From field' do
        expect(plain).to include("Foo <foo@example.com>")
      end

      it 'saves Sender field' do
        expect(plain).to include("Baz <baz@example.com>")
      end

      it 'saves Reply-to field' do
        expect(plain).to include("No Reply <no-reply@example.com>")
      end

      it 'saves To field' do
        expect(plain).to include("Bar <bar@example.com>")
      end

      it 'saves Subject field' do
        expect(plain).to include("Hello")
      end

      it 'saves Body with autolink' do
        expect(plain).to include('World! <a href="http://example.com">http://example.com</a>')
      end
    end

    context 'multipart' do
      let(:rich_file) { Dir["#{location}/*/rich.html"].first }
      let(:rich) { CGI.unescape_html(File.read(rich_file)) }

      before do
        expect(Launchy).to receive(:open)

        Mail.deliver do
          from    'foo@example.com'
          to      'bar@example.com'
          subject 'Many parts with <html>'
          text_part do
            body 'This is <plain> text'
          end
          html_part do
            content_type 'text/html; charset=UTF-8'
            body '<h1>This is HTML</h1>'
          end
        end
      end

      it 'creates plain html document' do
        expect(File.exist?(plain_file)).to be_truthy
      end

      it 'creates rich html document' do
        expect(File.exist?(rich_file)).to be_truthy
      end

      it 'shows link to rich html version' do
        expect(plain).to include("View HTML version")
      end

      it 'saves text part' do
        expect(plain).to include("This is <plain> text")
      end

      it 'saves html part' do
        expect(rich).to include("<h1>This is HTML</h1>")
      end

      it 'saves escaped Subject field' do
        expect(plain).to include("Many parts with <html>")
      end

      it 'shows subject as title' do
        expect(rich).to include("<title>Many parts with <html></title>")
      end
    end
  end

  context 'document with spaces in name' do
    let(:location) { File.expand_path('../../../tmp/letter_opener with space', __FILE__) }

    before do
      expect(Launchy).to receive(:open)

      Mail.deliver do
        from     'Foo <foo@example.com>'
        to       'bar@example.com'
        subject  'Hello'
        body     'World!'
      end
    end

    it 'creates plain html document' do
      File.exist?(plain_file)
    end

    it 'saves From filed' do
      expect(plain).to include("Foo <foo@example.com>")
    end
  end

  context 'using deliver! method' do
    before do
      expect(Launchy).to receive(:open)
      Mail.new do
        from    'foo@example.com'
        to      'bar@example.com'
        subject 'Hello'
        body    'World!'
      end.deliver!
    end

    it 'creates plain html document' do
      expect(File.exist?(plain_file)).to be_truthy
    end

    it 'saves From field' do
      expect(plain).to include("foo@example.com")
    end

    it 'saves To field' do
      expect(plain).to include("bar@example.com")
    end

    it 'saves Subject field' do
      expect(plain).to include("Hello")
    end

    it 'saves Body field' do
      expect(plain).to include("World!")
    end
  end

  context 'attachments in plain text mail' do
    before do
      Mail.deliver do
        from      'foo@example.com'
        to        'bar@example.com'
        subject   'With attachments'
        text_part do
          body 'This is <plain> text'
        end
        attachments[File.basename(__FILE__)] = File.read(__FILE__)
      end
    end

    it 'creates attachments dir with attachment' do
      attachment = Dir["#{location}/*/attachments/#{File.basename(__FILE__)}"].first
      expect(File.exist?(attachment)).to be_truthy
    end

    it 'saves attachment name' do
      plain = File.read(Dir["#{location}/*/plain.html"].first)
      expect(plain).to include(File.basename(__FILE__))
    end
  end

  context 'attachments in rich mail' do
    let(:url) { mail.attachments[0].url }

    let!(:mail) do
      Mail.deliver do
        from      'foo@example.com'
        to        'bar@example.com'
        subject   'With attachments'
        attachments[File.basename(__FILE__)] = File.read(__FILE__)
        url = attachments[0].url
        html_part do
          content_type 'text/html; charset=UTF-8'
          body "Here's an image: <img src='#{url}' />"
        end
      end
    end

    it 'creates attachments dir with attachment' do
      attachment = Dir["#{location}/*/attachments/#{File.basename(__FILE__)}"].first
      expect(File.exist?(attachment)).to be_truthy
    end

    it 'replaces inline attachment urls' do
      text = File.read(Dir["#{location}/*/rich.html"].first)
      expect(mail.parts[0].body).to include(url)
      expect(text).to_not include(url)
      expect(text).to include("attachments/#{File.basename(__FILE__)}")
    end
  end

  context 'attachments with non-word characters in the filename' do
    before do
      Mail.deliver do
        from      'foo@example.com'
        to        'bar@example.com'
        subject   'With attachments'
        text_part do
          body 'This is <plain> text'
        end
        attachments['non word:chars/used,01-02.txt'] = File.read(__FILE__)

        url = attachments[0].url
        html_part do
          content_type 'text/html; charset=UTF-8'
          body "This is an image: <img src='#{url}'>"
        end
      end
    end

    it 'creates attachments dir with attachment' do
      attachment = Dir["#{location}/*/attachments/non word-chars-used,01-02.txt"].first
      expect(File.exist?(attachment)).to be_truthy
    end

    it 'saves attachment name' do
      plain = File.read(Dir["#{location}/*/plain.html"].first)
      expect(plain).to include('non word-chars-used,01-02.txt')
    end

    it 'replaces inline attachment names' do
      text = File.read(Dir["#{location}/*/rich.html"].first)
      expect(text).to include('attachments/non word-chars-used,01-02.txt')
    end
  end

  context 'subjectless mail' do
    before do
      expect(Launchy).to receive(:open)

      Mail.deliver do
        from     'Foo foo@example.com'
        reply_to 'No Reply no-reply@example.com'
        to       'Bar bar@example.com'
        body     'World! http://example.com'
      end
    end

    it 'creates plain html document' do
      expect(File.exist?(plain_file)).to be_truthy
    end
  end

  context 'delivery params' do
    it 'raises an exception if there is no SMTP Envelope To value' do
      expect(Launchy).not_to receive(:open)

      expect {
        Mail.deliver do
          from     'Foo foo@example.com'
          reply_to 'No Reply no-reply@example.com'
          body     'World! http://example.com'
        end
      }.to raise_exception(ArgumentError)
    end

    it 'does not raise an exception if there is at least one SMTP Envelope To value' do
      expect(Launchy).to receive(:open)

      expect {
        Mail.deliver do
          from     'Foo foo@example.com'
          cc       'Bar bar@example.com'
          reply_to 'No Reply no-reply@example.com'
          body     'World! http://example.com'
        end
      }.not_to raise_exception
    end
  end

  context 'light template' do
    before do
      expect(Launchy).to receive(:open)

      LetterOpener.configure do |config|
        config.message_template = :light
      end

      Mail.defaults do
        delivery_method LetterOpener::DeliveryMethod, :location => File.expand_path('../../../tmp/letter_opener', __FILE__)
      end

      Mail.deliver do
        subject  'Foo subject'
        from     'Foo foo@example.com'
        reply_to 'No Reply no-reply@example.com'
        to       'Bar bar@example.com'
        body     'World! http://example.com'
      end
    end

    after do
      LetterOpener.configure do |config|
        config.message_template = :default
      end
    end

    it 'creates plain html document' do
      expect(File.exist?(plain_file)).to be_truthy
    end
  end

  context 'specifying custom file_uri_scheme configuration option' do
    after do
      Mail.defaults do
        delivery_method LetterOpener::DeliveryMethod, location: File.expand_path('../../../tmp/letter_opener', __FILE__)
      end

      Mail.deliver do
        subject  'Foo subject'
        from     'Foo foo@example.com'
        reply_to 'No Reply no-reply@example.com'
        to       'Bar bar@example.com'
        body     'World! http://example.com'
      end

      LetterOpener.configure do |config|
        config.file_uri_scheme = file_uri_scheme
      end
    end

    context 'file_uri_scheme is not set in configuration' do
      it "sends the path to Launchy with the 'file://' prefix by default" do
        allow(Launchy).to receive(:open) do |path|
          expect(path).not_to match(/^file:\/\//)
        end
      end
    end

    context 'file_uri_scheme is set in configuration' do
      it "sends the path to Launchy with the 'file://///wsl$/Ubuntu-18.04' prefix" do
        allow(Launchy).to receive(:open) do |path|
          expect(path).to match(/^file:\/\/\/\/\/wsl\$\/Ubuntu-18.04/)
        end

        LetterOpener.configure do |config|
          config.file_uri_scheme = 'file://///wsl$/Ubuntu-18.04'
        end
      end
    end
  end
end
