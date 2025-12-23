require "cgi"
require "erb"
require "fileutils"
require "uri"

module LetterOpener
  class Message
    attr_reader :mail

    def self.rendered_messages(mail, options = {})
      messages = []
      messages << new(mail, options.merge(part: mail.html_part)) if mail.html_part
      messages << new(mail, options.merge(part: mail.text_part)) if mail.text_part
      messages << new(mail, options) if messages.empty?
      messages.each(&:render)
      messages.sort
    end

    ERROR_MSG = '%s or default configuration must be given'.freeze

    def initialize(mail, options = {})
      @mail = mail
      @location = options[:location] || LetterOpener.configuration.location
      @part = options[:part]
      @template = options[:message_template] || LetterOpener.configuration.message_template
      @attachments = []

      raise ArgumentError, ERROR_MSG % 'options[:location]' unless @location
      raise ArgumentError, ERROR_MSG % 'options[:message_template]' unless @template
    end

    def render
      FileUtils.mkdir_p(@location)

      if mail.attachments.any?
        attachments_dir = File.join(@location, 'attachments')
        FileUtils.mkdir_p(attachments_dir)
        mail.attachments.each do |attachment|
          filename = attachment_filename(attachment)
          path = File.join(attachments_dir, filename)

          unless File.exist?(path) # true if other parts have already been rendered
            File.open(path, 'wb') { |f| f.write(attachment.body.raw_source) }
          end

          @attachments << [attachment.filename, "attachments/#{filename}"]
        end
      end

      File.open(filepath, 'w') do |f|
        f.write ERB.new(template).result(binding)
      end

      mail["location_#{type}"] = filepath
    end

    def template
      File.read(File.expand_path("../templates/#{@template}.html.erb", __FILE__))
    end

    def filepath
      File.join(@location, "#{type}.html")
    end

    def content_type
      @part && @part.content_type || @mail.content_type
    end

    def body
      @body ||= begin
        body = (@part || @mail).decoded

        mail.attachments.each do |attachment|
          body.gsub!(attachment.url, "attachments/#{attachment_filename(attachment)}")
        end

        body
      end
    end

    def from
      @from ||= Array(@mail['from']).join(", ")
    end

    def sender
      @sender ||= Array(@mail['sender']).join(", ")
    end

    def subject
      @subject ||= @mail.subject
    end

    def to
      @to ||= Array(@mail['to']).join(", ")
    end

    def cc
      @cc ||= Array(@mail['cc']).join(", ")
    end

    def bcc
      @bcc ||= Array(@mail['bcc']).join(", ")
    end

    def reply_to
      @reply_to ||= Array(@mail['reply-to']).join(", ")
    end

    def type
      content_type =~ /html/ ? "rich" : "plain"
    end

    def encoding
      body.respond_to?(:encoding) ? body.encoding : "utf-8"
    end

    def auto_link(text)
      text.gsub(URI::Parser.new.make_regexp(%W[https http])) do |link|
        "<a href=\"#{ link }\">#{ link }</a>"
      end
    end

    def h(content)
      CGI.escapeHTML(content)
    end

    def attachment_filename(attachment)
      # Copied from https://github.com/rails/rails/blob/6bfc637659248df5d6719a86d2981b52662d9b50/activestorage/app/models/active_storage/filename.rb#L57
      attachment.filename.encode(
        Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "�").strip.tr("\u{202E}%$|:;/\t\r\n\\", "-"
      )
    end

    def <=>(other)
      order = %w[rich plain]
      order.index(type) <=> order.index(other.type)
    end
  end
end
