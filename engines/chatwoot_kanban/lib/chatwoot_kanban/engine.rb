module ChatwootKanban
  # Isolated Rails Engine.
  #
  # Why isolate_namespace?
  #   - Models, controllers, policies and routes live under the ChatwootKanban::
  #     namespace, so they cannot collide with anything Chatwoot upstream adds.
  #   - The host app keeps its own routes file; we mount this engine with ONE line:
  #       mount ChatwootKanban::Engine, at: '/'
  #     (kept silent — the engine itself namespaces its API at /api/v1/...).
  module_function

  class Engine < ::Rails::Engine
    isolate_namespace ChatwootKanban

    # Make migrations from this engine show up when the host runs:
    #   bundle exec rails db:migrate
    initializer 'chatwoot_kanban.append_migrations' do |app|
      unless app.root.to_s == root.to_s
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end

    # Pundit policies in the engine resolve correctly when called from the host.
    initializer 'chatwoot_kanban.pundit' do
      ActiveSupport.on_load(:action_controller_base) do
        include Pundit::Authorization if defined?(Pundit) && !include?(Pundit::Authorization)
      end
    end

    # Optional: load YAML-defined defaults the engine ships with.
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
    end
  end
end
