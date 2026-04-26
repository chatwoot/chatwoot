# CUSTOMIZAÇÃO_SYNAPSEOS — tarefas operacionais da camada de dados.
# Documentadas em docs/synapseos/data_layer.md.

namespace :synapseos do
  desc 'Cria databases companheiros (n8n, dexi_gateway) no Postgres compartilhado. Idempotente.'
  task provision_companion_dbs: :environment do
    %w[n8n dexi_gateway].each do |db_name|
      exists = ActiveRecord::Base.connection.exec_query(
        "SELECT 1 FROM pg_database WHERE datname = $1",
        'companion-db check',
        [db_name]
      ).any?

      if exists
        puts "[synapseos] database '#{db_name}' já existe — pulando"
      else
        ActiveRecord::Base.connection.execute(%(CREATE DATABASE "#{db_name}"))
        puts "[synapseos] database '#{db_name}' criado"
      end
    end
  end

  desc 'Provisiona user Postgres read-only `n8n_reader` com SELECT nas tabelas relevantes. Use SYNAPSEOS_N8N_READER_PASSWORD env var.'
  task provision_n8n_reader: :environment do
    password = ENV['SYNAPSEOS_N8N_READER_PASSWORD']
    if password.blank?
      abort('[synapseos] SYNAPSEOS_N8N_READER_PASSWORD não definido. Gere com `openssl rand -hex 32` e exporte antes de rodar a task.')
    end

    conn = ActiveRecord::Base.connection
    db_name = conn.current_database

    # Cria role se não existe; reseta senha se já existe (rotação).
    role_exists = conn.exec_query(
      "SELECT 1 FROM pg_roles WHERE rolname = 'n8n_reader'"
    ).any?

    if role_exists
      conn.execute("ALTER USER n8n_reader WITH PASSWORD #{conn.quote(password)}")
      puts '[synapseos] role n8n_reader já existe — senha rotacionada'
    else
      conn.execute("CREATE USER n8n_reader WITH PASSWORD #{conn.quote(password)}")
      puts '[synapseos] role n8n_reader criada'
    end

    # Grants idempotentes.
    conn.execute(%(GRANT CONNECT ON DATABASE "#{db_name}" TO n8n_reader))
    conn.execute('GRANT USAGE ON SCHEMA public TO n8n_reader')
    conn.execute('GRANT SELECT ON ALL TABLES IN SCHEMA public TO n8n_reader')
    conn.execute('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO n8n_reader')

    # Defense in depth: revogar acesso a tabelas com secrets/tokens.
    sensitive_tables = %w[access_tokens installation_configs users active_storage_blobs]
    sensitive_tables.each do |t|
      next unless conn.exec_query("SELECT 1 FROM information_schema.tables WHERE table_name = '#{t}'").any?

      conn.execute("REVOKE SELECT ON #{t} FROM n8n_reader")
    end

    puts "[synapseos] grants aplicados em #{db_name}; revoke nas sensíveis: #{sensitive_tables.join(', ')}"
    puts ''
    puts 'Credencial pra cadastrar no n8n (Postgres credential):'
    puts "  host=postgres  port=5432  database=#{db_name}  user=n8n_reader  password=<a senha que você passou>"
  end
end
