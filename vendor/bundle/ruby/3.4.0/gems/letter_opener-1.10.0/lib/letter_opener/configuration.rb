module LetterOpener
  class Configuration
    attr_accessor :location, :message_template, :file_uri_scheme

    def initialize
      @location = Rails.root.join('tmp', 'letter_opener') if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
      @message_template = 'default'
      @file_uri_scheme = nil
    end
  end
end
