namespace :socialwise do
  desc "Configura o hook do Socialwise para uma conta específica"
  task :setup, [:account_id] => :environment do |t, args|
    puts "==========================================".colorize(:cyan)
    puts "  CONFIGURAÇÃO HOOK SOCIALWISE"
    puts "==========================================".colorize(:cyan)
    
    account_id = args[:account_id] || ENV['ACCOUNT_ID'] || 2
    
    account = Account.find_by(id: account_id)
    unless account
      puts "❌ Conta não encontrada: #{account_id}".colorize(:red)
      exit
    end
    
    puts "📋 Configurando para conta: #{account.name} (ID: #{account.id})"
    
    # Verificar se já existe hook do Socialwise
    existing_hook = account.hooks.find_by(app_id: 'socialwise_chatwit')
    
    if existing_hook
      puts "⚠️  Hook Socialwise já existe (ID: #{existing_hook.id})".colorize(:yellow)
      puts "   Status: #{existing_hook.status}"
      puts "   Settings: #{existing_hook.settings}"
      
      # Atualizar para enabled se necessário
      if existing_hook.status != 'enabled' || existing_hook.settings&.dig('enabled') != true
        puts "🔄 Atualizando hook existente..."
        existing_hook.update!(
          status: 'enabled',
          settings: { 'enabled' => true }
        )
        puts "✅ Hook atualizado com sucesso!"
      else
        puts "✅ Hook já está configurado corretamente!"
      end
    else
      puts "🆕 Criando novo hook do Socialwise..."
      
      # Criar novo hook
      hook = account.hooks.create!(
        app_id: 'socialwise_chatwit',
        status: 'enabled',
        hook_type: 'account',
        settings: { 'enabled' => true }
      )
      
      puts "✅ Hook criado com sucesso!"
      puts "   ID: #{hook.id}"
      puts "   Status: #{hook.status}"
      puts "   Settings: #{hook.settings}"
    end
    
    # Verificar se existe hook do Dialogflow (informativo apenas)
    dialogflow_hook = account.hooks.find_by(app_id: 'dialogflow')
    if dialogflow_hook
      puts "ℹ️  Hook Dialogflow encontrado (ID: #{dialogflow_hook.id}) - Socialwise funcionará com Dialogflow".colorize(:blue)
    else
      puts "ℹ️  Hook Dialogflow não encontrado - Socialwise funcionará independentemente".colorize(:blue)
    end
    
    puts ""
    puts "🎉 Configuração concluída!".colorize(:green)
  end
  
  desc "Lista todos os hooks do Socialwise"
  task :list => :environment do
    puts "==========================================".colorize(:cyan)
    puts "  HOOKS SOCIALWISE EXISTENTES"
    puts "==========================================".colorize(:cyan)
    
    hooks = Integrations::Hook.where(app_id: 'socialwise_chatwit')
    
    if hooks.empty?
      puts "❌ Nenhum hook Socialwise encontrado".colorize(:red)
    else
      hooks.each do |hook|
        puts "📋 Hook ID: #{hook.id}"
        puts "   Conta: #{hook.account.name} (ID: #{hook.account_id})"
        puts "   Status: #{hook.status}"
        puts "   Settings: #{hook.settings}"
        puts "   Criado em: #{hook.created_at}"
        puts ""
      end
    end
  end
end 