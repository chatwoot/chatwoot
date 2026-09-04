module Enterprise::WebCrawling::Factory
  def providers
    super.merge(
      firecrawl: WebCrawling::Firecrawl::Spider,
      context_dev: WebCrawling::ContextDev::Spider
    )
  end

  def configured_provider
    provider = InstallationConfig.find_by(name: WebCrawling::Factory::CONFIG_KEY)&.value
    return provider.to_sym if provider.present? && provider != 'auto'

    WebCrawling::Firecrawl::Spider.configured? ? :firecrawl : :native
  end
end
