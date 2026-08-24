class WebCrawling::Factory
  class << self
    def build(provider: :native)
      providers.fetch(provider.to_sym).new
    end

    def providers
      { native: WebCrawling::Native::Spider }
    end
  end
end
