# frozen_string_literal: true

# Custom overlay — este arquivo NUNCA é sobrescrito por updates do Chatwoot upstream.
#
# Registra os valores de InstallationConfig que ativam o plano Enterprise completo,
# sem limite de licença e sem depender do chatwoot.com/hub online.
#
# Valores definidos:
#   INSTALLATION_PRICING_PLAN          → 'enterprise'
#   INSTALLATION_PRICING_PLAN_QUANTITY → 999999  (ilimitado na prática)
#
# Executado apenas após a inicialização completa do Rails e somente se a tabela
# installation_configs já existir (evita erros durante db:create / db:migrate iniciais).

Rails.application.config.after_initialize do
  next unless defined?(InstallationConfig)
  next unless ActiveRecord::Base.connection.table_exists?('installation_configs')

  [
    { name: 'INSTALLATION_PRICING_PLAN',         value: 'enterprise' },
    { name: 'INSTALLATION_PRICING_PLAN_QUANTITY', value: 999_999 }
  ].each do |config|
    record = InstallationConfig.find_or_initialize_by(name: config[:name])
    # Só escreve se o valor atual for o default community ou zero,
    # para não sobrescrever uma configuração deliberada do admin.
    next if record.persisted? && record.value.to_s == config[:value].to_s

    record.value = config[:value]
    record.save!
  end
rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
  # Banco ainda não criado — ignorar silenciosamente
end
