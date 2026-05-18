require 'chatwoot_glpi_integration/version'
require 'chatwoot_glpi_integration/engine'

module ChatwootGlpiIntegration
  class Configuration
    attr_accessor :webhook_secret_env, :token_cache_ttl, :default_itil_category_id,
                  :default_request_type_id

    def initialize
      @webhook_secret_env       = 'CHATWOOT_GLPI_WEBHOOK_SECRET'
      @token_cache_ttl          = 50.minutes    # GLPI OAuth tokens last 60min
      @default_itil_category_id = nil
      @default_request_type_id  = 1             # 1 = Helpdesk by default in GLPI
    end
  end

  class << self
    def configuration = (@configuration ||= Configuration.new)
    def configure                = yield(configuration)
  end
end
