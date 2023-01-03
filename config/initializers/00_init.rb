APPS_CONFIG = YAML.load_file(Rails.root.join('config/integration/apps.yml'))

require 'microsoft_graph_auth'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :microsoft_graph_auth,
           ENV.fetch('AZURE_APP_ID'),
           ENV.fetch('AZURE_APP_SECRET'),
           scope: ENV.fetch('AZURE_SCOPES')
end
