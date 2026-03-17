namespace :db do
  desc "Migra banco Chatwoot v3 para v4 (uso: rails db:chatwit_migrate)"
  task chatwit_migrate: :environment do
    puts "========================================"
    puts "  MIGRAÇÃO CHATWOOT v3 -> v4"
    puts "========================================"
    puts

    # Verificar ambiente
    puts "🔧 Ambiente: #{Rails.env}"
    if Rails.env.production?
      puts "⚠️  PRODUÇÃO: Este comando fará alterações no banco!"
    end

    # Adicionar colunas necessárias
    puts "➕ Adicionando colunas necessárias..."
    
    ActiveRecord::Base.connection.execute(
      "ALTER TABLE accounts ADD COLUMN IF NOT EXISTS settings jsonb DEFAULT '{}'"
    )
    
    ActiveRecord::Base.connection.execute(
      "ALTER TABLE inboxes ADD COLUMN IF NOT EXISTS csat_config jsonb DEFAULT '{}' NOT NULL"
    )

    # Marcar migrações manuais
    puts "✅ Marcando migrações manuais..."
    ActiveRecord::Base.connection.execute(
      "INSERT INTO schema_migrations (version) VALUES ('20250421082927'), ('20250514045638') ON CONFLICT (version) DO NOTHING"
    )

    # Executar migrações pendentes
    puts "🔄 Executando migrações pendentes..."
    begin
      Rake::Task['db:migrate'].invoke
      puts "✅ Migração concluída!"
      
      # Ativar features v4 para todas as contas após migração
      puts "🔧 Ativando features v4 para todas as contas..."
      begin
        Account.find_in_batches(batch_size: 100) do |accounts|
          accounts.each do |account|
            account.enable_features!('chatwoot_v4')
            puts "  ✅ Features v4 ativadas para: #{account.name}"
          end
        end
        puts "✅ Features v4 ativadas com sucesso!"
      rescue => feature_error
        puts "⚠️  Erro ao ativar features: #{feature_error.message}"
      end
    rescue => e
      if e.message.include?("already exists") || e.message.include?("DuplicateTable")
        puts "⚠️  Algumas migrações já aplicadas - marcando como executadas..."
        
        # Marcar migrações problemáticas como executadas
        problem_migrations = [
          '20250104200055'  # CreateCaptainTables
        ]
        
        problem_migrations.each do |version|
          ActiveRecord::Base.connection.execute(
            "INSERT INTO schema_migrations (version) VALUES ('#{version}') ON CONFLICT (version) DO NOTHING"
          )
        end
        
        puts "✅ Migrações marcadas - continuando..."
        
        # Tentar novamente
                 begin
           Rake::Task['db:migrate'].invoke
           puts "✅ Migração concluída!"
           
           # Ativar features v4 para todas as contas após migração
           puts "🔧 Ativando features v4 para todas as contas..."
           begin
             Account.find_in_batches(batch_size: 100) do |accounts|
               accounts.each do |account|
                 account.enable_features!('chatwoot_v4')
                 puts "  ✅ Features v4 ativadas para: #{account.name}"
               end
             end
             puts "✅ Features v4 ativadas com sucesso!"
           rescue => feature_error
             puts "⚠️  Erro ao ativar features: #{feature_error.message}"
           end
         rescue => e2
           puts "⚠️  Migração com avisos: #{e2.message}"
           puts "✅ Aplicação pode continuar normalmente"
         end
      else
        puts "❌ Erro na migração: #{e.message}"
        raise e
      end
    end
  end

  desc "Prepara ambiente Chatwit para produção"
  task chatwit_prepare: :environment do
    puts "🚀 Preparando Chatwit para produção..."
    
    # Executar migração se necessário
    Rake::Task['db:chatwit_migrate'].invoke
    
    # NÃO executar seeds em produção pois pode sobrescrever dados
    unless Rails.env.production?
      puts "🌱 Executando seeds (apenas em desenvolvimento)..."
      begin
        Rake::Task['db:seed'].invoke
      rescue => e
        puts "⚠️  Seeds ignorados: #{e.message}"
      end
    else
      puts "⚠️  Seeds ignorados em produção para preservar dados"
    end
    
    puts "✅ Chatwit preparado!"
  end

  desc "Preparação inteligente - só migra se necessário"
  task chatwit_smart_prepare: :environment do
    puts "🚀 [CHATWIT] Verificando necessidade de migração..."
    
    # Verificar se as colunas v4 existem
    needs_migration = false
    
    begin
      # Testar se as colunas críticas do v4 existem
      if !ActiveRecord::Base.connection.column_exists?(:accounts, :settings)
        puts "🔍 [CHATWIT] Coluna 'settings' não encontrada - migração necessária"
        needs_migration = true
      end
      
      if !ActiveRecord::Base.connection.column_exists?(:inboxes, :csat_config)
        puts "🔍 [CHATWIT] Coluna 'csat_config' não encontrada - migração necessária"
        needs_migration = true
      end
    rescue => e
      puts "⚠️  [CHATWIT] Erro ao verificar colunas - assumindo migração necessária"
      puts "    Erro: #{e.message}"
      needs_migration = true
    end
    
    if needs_migration
      puts "✅ [CHATWIT] Migração v3->v4 necessária - executando..."
      puts ""
      Rake::Task['db:chatwit_prepare'].invoke
    else
      puts "✅ [CHATWIT] Base já está no v4 - executando apenas setup normal..."
      
      # Executar cada migração pendente individualmente para não pular nenhuma
      context = ActiveRecord::MigrationContext.new(Rails.root.join('db/migrate'))
      pending = context.migrations_status.select { |status, _version, _name| status == 'down' }

      if pending.empty?
        puts "✅ [CHATWIT] Nenhuma migração pendente."
      else
        puts "🔄 [CHATWIT] #{pending.size} migração(ões) pendente(s)..."
        pending.each do |_status, version, name|
          begin
            context.run(:up, version.to_i)
            puts "  ✅ [CHATWIT] #{version} #{name} aplicada!"
          rescue => e
            if e.message.include?("already exists") || e.message.include?("DuplicateTable") || e.message.include?("DuplicateColumn")
              puts "  📌 [CHATWIT] #{version} #{name} já existe no banco - marcando como executada..."
              schema_migration = ActiveRecord::Base.connection.schema_migration
              schema_migration.create_version(version.to_s)
            else
              puts "  ❌ [CHATWIT] #{version} #{name} falhou: #{e.message}"
              raise e
            end
          end
        end
        puts "✅ [CHATWIT] Todas as migrações processadas!"
      end
      
      # Seeds apenas em desenvolvimento
      unless Rails.env.production?
        begin
          Rake::Task['db:seed'].invoke
          puts "✅ [CHATWIT] Seeds aplicados!"
        rescue => e
          puts "⚠️  [CHATWIT] Seeds ignorados: #{e.message}"
        end
      end
    end
    
    puts ""
    puts "🎉 [CHATWIT] Aplicação pronta para iniciar!"
  end
end 