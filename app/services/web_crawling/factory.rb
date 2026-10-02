class WebCrawling::Factory
  CONFIG_KEY = 'WEB_CRAWLING_PROVIDER'.freeze

  class ConfigurationError < StandardError; end

  class << self
    def build(provider: configured_provider)
      provider_class = providers.fetch(provider.to_sym)
      raise ConfigurationError, "Web crawler provider '#{provider}' is not configured" unless provider_class.configured?

      provider_class.new
    end

    def providers
      { native: WebCrawling::Native::Spider }
    end

    def configured_provider
      :native
    end
  end
end

WebCrawling::Factory.singleton_class.prepend_mod_with('WebCrawling::Factory')
