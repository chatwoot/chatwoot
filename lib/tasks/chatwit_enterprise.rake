# Chatwit — Blindagem da edição Enterprise
#
# Garante, de forma idempotente, que a instalação rode como self-hosted
# enterprise white-label. Roda em DOIS pontos:
#   - no boot, via initializer Chatwit::EnterprisePlan (config/initializers/00_chatwit.rb)
#   - a cada deploy, enganchado em db:chatwoot_prepare (enhance no final deste arquivo)
#
# Cobre os footguns que já travaram o Enterprise:
#   1. INSTALLATION_PRICING_PLAN cai em 'community' (default do seed) → pricing_plan
#      vira community e o ReconcilePlanConfigService (upstream v4.13.0) DESABILITA
#      as features premium em todas as contas.
#   2. DISABLE_ENTERPRISE="false" — string truthy em Ruby que desliga a edição
#      Enterprise inteira (lib/chatwoot_app.rb). Não dá pra "consertar" a env de
#      dentro do Ruby (enterprise? é memoizado no boot); aqui apenas alertamos.
#      A sanitização real (unset quando falsey) está nos entrypoints docker.

namespace :chatwit do
  desc 'Blinda a edição Enterprise (plano + features premium). Idempotente.'
  task :enterprise_guard do
    unless ActiveRecord::Base.connection.table_exists?('installation_configs')
      puts '[CHATWIT-GUARD] Pulando — tabela installation_configs ainda não existe.'
      next
    end

    premium_features = %w[disable_branding audit_logs sla captain_integration custom_roles response_bot].freeze

    pin = lambda do |name, value|
      cfg = InstallationConfig.find_or_initialize_by(name: name)
      next false if cfg.value.to_s == value.to_s

      cfg.value = value
      cfg.locked = true
      cfg.save!
      true
    end

    changed = pin.call('INSTALLATION_PRICING_PLAN', 'enterprise')
    pin.call('INSTALLATION_PRICING_PLAN_QUANTITY', '100')
    GlobalConfig.clear_cache if changed

    if ActiveRecord::Base.connection.column_exists?(:accounts, :settings)
      Account.find_each { |account| account.enable_features!(*premium_features) }
    end

    if ENV.key?('DISABLE_ENTERPRISE')
      warn '[CHATWIT-GUARD] ⚠️  DISABLE_ENTERPRISE está setada — "false" é TRUTHY em Ruby e DESLIGA o Enterprise. ' \
           'Remova a env (unset) na stack/compose. Os entrypoints docker já sanitizam no boot.'
    end

    puts "[CHATWIT-GUARD] ✅ Enterprise blindado — plano=enterprise, #{premium_features.size} features premium habilitadas."
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished => e
    puts "[CHATWIT-GUARD] Pulando — banco indisponível: #{e.message}"
  end
end

# NOTE: o enhance que roda esta task ao final de `db:chatwoot_prepare` fica em
# lib/tasks/db_enhancements.rake (carregado DEPOIS deste arquivo na ordem
# alfabética, garantindo que a task db:chatwoot_prepare já exista no attach).
