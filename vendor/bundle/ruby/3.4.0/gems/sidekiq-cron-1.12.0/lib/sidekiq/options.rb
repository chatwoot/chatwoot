require 'sidekiq'

module Sidekiq
  module Options
    def self.[](key)
      self.config[key]
    end

    def self.[]=(key, value)
      self.config[key] = value
    end

    def self.config
      options_field ? Sidekiq.public_send(options_field) : Sidekiq
    end

    def self.options_field
      return @options_field unless @options_field.nil?
      sidekiq_version = Gem::Version.new(Sidekiq::VERSION)
      @options_field = if sidekiq_version >= Gem::Version.new('7.0')
        :default_configuration
      elsif sidekiq_version >= Gem::Version.new('6.5')
        false
      else
        :options
      end
    end
  end
end
