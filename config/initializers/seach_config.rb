class SearchConfig
  class << self
    def enabled?
      opensearch_url.present?
    end

    def setup!
      return unless enabled?

      Searchkick.client_options = client_options
    end

    def client_options
      {
        url: opensearch_url,
        transport_options: {
          request: { timeout: timeout }
        }
      }
    end

    private

    def opensearch_url
      ENV.fetch('OPENSEARCH_URL', nil)
    end

    def timeout
      ENV.fetch('OPENSEARCH_TIMEOUT', 10).to_i
    end
  end
end
