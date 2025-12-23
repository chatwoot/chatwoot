require 'yaml'

module Mail
  module YAML
    def self.load(yaml)
      permitted_classes = [
        Symbol,

        Mail::Body,

        # Delivery methods as listed in mail/configuration.rb
        Mail::SMTP,
        Mail::Sendmail,
        Mail::Exim,
        Mail::FileDelivery,
        Mail::SMTPConnection,
        Mail::TestMailer,
        Mail::LoggerDelivery,

        Mail.delivery_method.class,
      ]

      if Gem::Version.new(Psych::VERSION) >= Gem::Version.new('3.1.0.pre1')
        ::YAML.safe_load(yaml, :permitted_classes => permitted_classes)
      else
        ::YAML.safe_load(yaml, permitted_classes)
      end
    end
  end
end
