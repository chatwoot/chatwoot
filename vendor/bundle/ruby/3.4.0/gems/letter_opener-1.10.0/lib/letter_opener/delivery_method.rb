require "digest/sha1"
require "launchy"

module LetterOpener
  class DeliveryMethod
    class InvalidOption < StandardError; end

    attr_accessor :settings

    def initialize(options = {})
      options[:message_template] ||= LetterOpener.configuration.message_template
      options[:location] ||= LetterOpener.configuration.location
      options[:file_uri_scheme] ||= LetterOpener.configuration.file_uri_scheme

      raise InvalidOption, "A location option is required when using the Letter Opener delivery method" if options[:location].nil?

      self.settings = options
    end

    def deliver!(mail)
      validate_mail!(mail)
      location = File.join(settings[:location], "#{Time.now.to_f.to_s.tr('.', '_')}_#{Digest::SHA1.hexdigest(mail.encoded)[0..6]}")

      messages = Message.rendered_messages(mail, location: location, message_template: settings[:message_template])
      ::Launchy.open("#{settings[:file_uri_scheme]}#{messages.first.filepath}")
    end

    private

    def validate_mail!(mail)
      if !mail.smtp_envelope_from || mail.smtp_envelope_from.empty?
        raise ArgumentError, "SMTP From address may not be blank"
      end

      if !mail.smtp_envelope_to || mail.smtp_envelope_to.empty?
        raise ArgumentError, "SMTP To address may not be blank"
      end
    end
  end
end
