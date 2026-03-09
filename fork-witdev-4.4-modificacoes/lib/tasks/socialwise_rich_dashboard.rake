namespace :socialwise do
  namespace :rich_dashboard do
    desc 'Enable SOCIALWISE_RICH_DASHBOARD feature flag for a specific account'
    task :enable, [:account_id] => :environment do |_task, args|
      account_id = args[:account_id]
      
      if account_id.blank?
        puts "❌ Erro: ID da conta é obrigatório"
        puts "Uso: rails socialwise:rich_dashboard:enable[ACCOUNT_ID]"
        puts "Exemplo: rails socialwise:rich_dashboard:enable[3]"
        exit 1
      end

      account = Account.find_by(id: account_id)
      unless account
        puts "❌ Erro: Conta com ID #{account_id} não encontrada"
        exit 1
      end

      # Habilitar a feature flag para a conta
      Feature.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, account_id.to_i, true)
      
      puts "✅ Feature flag SOCIALWISE_RICH_DASHBOARD habilitada para a conta #{account_id} (#{account.name})"
      
      # Verificar se foi habilitada corretamente
      enabled = Feature.get(:SOCIALWISE_RICH_DASHBOARD, account_id.to_i)
      puts "✅ Verificação: Feature flag está #{enabled ? 'HABILITADA' : 'DESABILITADA'}"
      
      # Mostrar todas as flags da conta
      flags = AccountFeatureFlag.where(account_id: account_id)
      puts "\n📋 Todas as feature flags da conta #{account_id}:"
      if flags.any?
        flags.each do |flag|
          status = flag.enabled ? '✅ HABILITADA' : '❌ DESABILITADA'
          puts "  - #{flag.flag_name}: #{status}"
        end
      else
        puts "  Nenhuma feature flag específica encontrada"
      end
    end

    desc 'Disable SOCIALWISE_RICH_DASHBOARD feature flag for a specific account'
    task :disable, [:account_id] => :environment do |_task, args|
      account_id = args[:account_id]
      
      if account_id.blank?
        puts "❌ Erro: ID da conta é obrigatório"
        puts "Uso: rails socialwise:rich_dashboard:disable[ACCOUNT_ID]"
        puts "Exemplo: rails socialwise:rich_dashboard:disable[3]"
        exit 1
      end

      account = Account.find_by(id: account_id)
      unless account
        puts "❌ Erro: Conta com ID #{account_id} não encontrada"
        exit 1
      end

      # Desabilitar a feature flag para a conta
      Feature.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, account_id.to_i, false)
      
      puts "❌ Feature flag SOCIALWISE_RICH_DASHBOARD desabilitada para a conta #{account_id} (#{account.name})"
      
      # Verificar se foi desabilitada corretamente
      enabled = Feature.get(:SOCIALWISE_RICH_DASHBOARD, account_id.to_i)
      puts "✅ Verificação: Feature flag está #{enabled ? 'HABILITADA' : 'DESABILITADA'}"
    end

    desc 'Enable SOCIALWISE_RICH_DASHBOARD globally for all accounts'
    task :enable_global => :environment do
      # Habilitar globalmente via InstallationConfig
      config = InstallationConfig.find_or_create_by(name: 'SOCIALWISE_RICH_DASHBOARD')
      config.update!(value: true, locked: false)
      
      puts "✅ Feature flag SOCIALWISE_RICH_DASHBOARD habilitada GLOBALMENTE"
      puts "📝 Todas as contas agora têm acesso ao Rich Dashboard (exceto as que têm flags específicas desabilitadas)"
      
      # Mostrar contas com flags específicas
      specific_flags = AccountFeatureFlag.where(flag_name: 'SOCIALWISE_RICH_DASHBOARD')
      if specific_flags.any?
        puts "\n📋 Contas com configurações específicas:"
        specific_flags.includes(:account).each do |flag|
          status = flag.enabled ? '✅ HABILITADA' : '❌ DESABILITADA'
          puts "  - Conta #{flag.account_id} (#{flag.account.name}): #{status}"
        end
      end
    end

    desc 'Disable SOCIALWISE_RICH_DASHBOARD globally for all accounts'
    task :disable_global => :environment do
      # Desabilitar globalmente via InstallationConfig
      config = InstallationConfig.find_or_create_by(name: 'SOCIALWISE_RICH_DASHBOARD')
      config.update!(value: false, locked: false)
      
      puts "❌ Feature flag SOCIALWISE_RICH_DASHBOARD desabilitada GLOBALMENTE"
      puts "📝 Nenhuma conta tem acesso ao Rich Dashboard (exceto as que têm flags específicas habilitadas)"
      
      # Mostrar contas com flags específicas
      specific_flags = AccountFeatureFlag.where(flag_name: 'SOCIALWISE_RICH_DASHBOARD', enabled: true)
      if specific_flags.any?
        puts "\n📋 Contas que ainda têm acesso (flags específicas habilitadas):"
        specific_flags.includes(:account).each do |flag|
          puts "  - Conta #{flag.account_id} (#{flag.account.name}): ✅ HABILITADA"
        end
      end
    end

    desc 'Check SOCIALWISE_RICH_DASHBOARD status for a specific account'
    task :status, [:account_id] => :environment do |_task, args|
      account_id = args[:account_id]
      
      if account_id.blank?
        puts "❌ Erro: ID da conta é obrigatório"
        puts "Uso: rails socialwise:rich_dashboard:status[ACCOUNT_ID]"
        puts "Exemplo: rails socialwise:rich_dashboard:status[3]"
        exit 1
      end

      account = Account.find_by(id: account_id)
      unless account
        puts "❌ Erro: Conta com ID #{account_id} não encontrada"
        exit 1
      end

      # Verificar status da feature flag
      enabled = Feature.get(:SOCIALWISE_RICH_DASHBOARD, account_id.to_i)
      status = enabled ? '✅ HABILITADA' : '❌ DESABILITADA'
      
      puts "📊 Status da Feature Flag SOCIALWISE_RICH_DASHBOARD"
      puts "Conta: #{account_id} (#{account.name})"
      puts "Status: #{status}"
      
      # Verificar configuração global
      global_config = InstallationConfig.find_by(name: 'SOCIALWISE_RICH_DASHBOARD')
      global_status = global_config&.value ? '✅ HABILITADA' : '❌ DESABILITADA'
      puts "Global: #{global_status}"
      
      # Verificar flag específica da conta
      account_flag = AccountFeatureFlag.find_by(account_id: account_id, flag_name: 'SOCIALWISE_RICH_DASHBOARD')
      if account_flag
        account_status = account_flag.enabled ? '✅ HABILITADA' : '❌ DESABILITADA'
        puts "Específica da conta: #{account_status} (sobrescreve global)"
      else
        puts "Específica da conta: Não definida (usa configuração global)"
      end
    end

    desc 'List all accounts with SOCIALWISE_RICH_DASHBOARD enabled'
    task :list_enabled => :environment do
      puts "📋 Contas com SOCIALWISE_RICH_DASHBOARD habilitada:\n"
      
      # Verificar configuração global
      global_config = InstallationConfig.find_by(name: 'SOCIALWISE_RICH_DASHBOARD')
      global_enabled = global_config&.value
      
      if global_enabled
        puts "🌍 CONFIGURAÇÃO GLOBAL: ✅ HABILITADA"
        puts "   Todas as contas têm acesso (exceto as com flags específicas desabilitadas)\n"
        
        # Mostrar contas com flags específicas desabilitadas
        disabled_flags = AccountFeatureFlag.where(flag_name: 'SOCIALWISE_RICH_DASHBOARD', enabled: false)
        if disabled_flags.any?
          puts "❌ Contas com acesso DESABILITADO (flags específicas):"
          disabled_flags.includes(:account).each do |flag|
            puts "  - Conta #{flag.account_id} (#{flag.account.name})"
          end
          puts ""
        end
      else
        puts "🌍 CONFIGURAÇÃO GLOBAL: ❌ DESABILITADA"
        puts "   Apenas contas com flags específicas têm acesso\n"
      end
      
      # Mostrar contas com flags específicas habilitadas
      enabled_flags = AccountFeatureFlag.where(flag_name: 'SOCIALWISE_RICH_DASHBOARD', enabled: true)
      if enabled_flags.any?
        puts "✅ Contas com acesso HABILITADO (flags específicas):"
        enabled_flags.includes(:account).each do |flag|
          puts "  - Conta #{flag.account_id} (#{flag.account.name})"
        end
      elsif !global_enabled
        puts "❌ Nenhuma conta tem acesso ao Rich Dashboard"
      end
    end
  end
end