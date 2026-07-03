# B1 (Onda 6) — registra o tipo pgvector `halfvec` no adapter PostgreSQL do ActiveRecord para que o
# schema.rb consiga DUMPAR e CARREGAR a coluna `autonomia_agent_knowledge.embedding_large`
# (halfvec 3072, usada no upgrade de embedding text-embedding-3-large @ 3072 dims). Sem isto, o
# schema dumper falha com "Unknown type 'halfvec(3072)'" e OMITE a tabela de conhecimento inteira —
# `db:schema:load` (bootstrap de env novo / CI) criaria a base SEM essa tabela (regressão grave).
#
# Espelha EXATAMENTE o que a gem `neighbor` faz para o tipo `vector` (ver neighbor.rb::RegisterTypes),
# porém SEM tocar a gem — `neighbor 0.2.3` fica intocada servindo as colunas `vector(1536)` do
# Autonomia legado e do Captain (garantia de zero-regressão por construção, não por teste). O VALOR do
# halfvec é lido/escrito por SQL cru no Retriever/Ingestor; aqui só ensinamos o dumper/loader a
# reconhecer o TIPO. Idempotente (só registra o que ainda não existe).
module AutonomiaHalfvecRegisterTypes
  def initialize_type_map(mapping = type_map)
    super
    mapping.register_type 'halfvec' do |_, _, sql_type|
      limit = extract_limit(sql_type)
      ActiveRecord::ConnectionAdapters::PostgreSQL::OID::SpecializedString.new(:halfvec, limit: limit)
    end
  end
end

ActiveSupport.on_load(:active_record) do
  require 'active_record/connection_adapters/postgresql_adapter'

  native = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES
  native[:halfvec] = { name: 'halfvec' } unless native.key?(:halfvec)

  table_def = ActiveRecord::ConnectionAdapters::TableDefinition
  table_def.send(:define_column_methods, :halfvec) unless table_def.method_defined?(:halfvec)

  adapter = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  registered = adapter.singleton_class.ancestors.include?(AutonomiaHalfvecRegisterTypes)
  adapter.singleton_class.prepend(AutonomiaHalfvecRegisterTypes) unless registered
end
