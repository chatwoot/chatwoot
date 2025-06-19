# Enterprise Mode - Ativa todas as features para qualquer instalação
Rails.application.configure do
  config.after_initialize do
    if defined?(Account) && Account.table_exists?
      # Valor máximo para feature_flags (todas as features ativadas)
      enterprise_flags = (2**63) - 1

      # Atualizar contas existentes que não são enterprise
      Account.where('feature_flags < ?', enterprise_flags).update_all(feature_flags: enterprise_flags)

      # Garantir que novas contas sejam enterprise por padrão
      Account.class_eval do
        after_create :ensure_enterprise_features

        private

        def ensure_enterprise_features
          return if feature_flags >= (2**63) - 1

          update_column(:feature_flags, (2**63) - 1)
        end
      end

      Rails.logger.info '✅ Enterprise Mode: Todas as features ativadas automaticamente'
    end
  end
end

# Configurar como Enterprise Edition
Rails.application.configure do
  config.chatwoot_edition = 'enterprise'
  config.enterprise_plan = 'enterprise'

  # Desabilitar verificações de licença
  config.after_initialize do
    if defined?(InstallationConfig)
      InstallationConfig.find_or_create_by(name: 'CHATWOOT_EDITION') do |config|
        config.value = 'enterprise'
      end

      InstallationConfig.find_or_create_by(name: 'ENTERPRISE_PLAN') do |config|
        config.value = 'enterprise'
      end

      Rails.logger.info '✅ Enterprise Edition: Configuração aplicada'
    end
  end
end

# Configurar ChatwootHub para Enterprise
Rails.application.configure do
  config.after_initialize do
    if defined?(InstallationConfig)
      # Garantir que o plano seja enterprise
      InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN') do |config|
        config.value = 'enterprise'
      end

      InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY') do |config|
        config.value = '999999'
      end

      Rails.logger.info '✅ ChatwootHub: Configurado para Enterprise plan'
    end
  end
end
