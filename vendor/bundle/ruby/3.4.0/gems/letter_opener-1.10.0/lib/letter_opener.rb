module LetterOpener
  autoload :Message, "letter_opener/message"
  autoload :DeliveryMethod, "letter_opener/delivery_method"
  autoload :Configuration, "letter_opener/configuration"

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end

require "letter_opener/railtie" if defined?(Rails::Railtie)
