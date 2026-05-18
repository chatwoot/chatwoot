module ChatwootGlpiIntegration
  class Engine < ::Rails::Engine
    isolate_namespace ChatwootGlpiIntegration

    initializer 'chatwoot_glpi_integration.append_migrations' do |app|
      unless app.root.to_s == root.to_s
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
    end
  end
end
