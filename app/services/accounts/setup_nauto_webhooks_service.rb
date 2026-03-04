module Accounts
  class SetupNautoWebhooksService
    WEBHOOKS = [
      { subscription: 'faq_catalog_updated', path: '/sync/faqs', name: 'Catálogo de FAQs Actualizado' },
      { subscription: 'product_catalog_updated', path: '/sync/products_catalog', name: 'Catálogo de Productos Actualizado' },
      { subscription: 'kb_resource_updated', path: '/sync/knowledge', name: 'Recurso de Base de Conocimiento Actualizado' }
    ].freeze

    def initialize(account)
      @account = account
    end

    def perform
      base_url = ENV.fetch('NAUTO_ASSISTANT_URL', nil)
      return if base_url.blank?

      WEBHOOKS.each do |config|
        @account.webhooks.create(
          name: config[:name],
          url: "#{base_url}#{config[:path]}",
          subscriptions: [config[:subscription]]
        )
      end

      AgentBot.create(
        account: @account,
        name: "#{@account.name} AI",
        outgoing_url: "#{base_url}/unified_webhook"
      )
    end
  end
end
