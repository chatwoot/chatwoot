namespace :autonomia do
  # Backfill RE-EMBED-ONLY do embedding_large (3-large/halfvec) na base Autônoma existente. Fase 1 do
  # cutover big-bang p/ 3-large, SEM regressão (não deleta, não re-chunka; a coluna 3-small segue
  # servindo até o flip). Idempotente/resumível. NÃO faz o cutover — após validar as contagens, o flip
  # é manual: InstallationConfig AUTONOMIA_EMBEDDING_MODEL=text-embedding-3-large.
  #
  #   bundle exec rails autonomia:backfill_large_embeddings                 # toda a base
  #   ACCOUNT_IDS=3,6 bundle exec rails autonomia:backfill_large_embeddings # só essas contas (ondas)
  desc 'Preenche embedding_large (3-large/halfvec) nos KnowledgeEntry existentes (re-embed-only, no-regression)'
  task backfill_large_embeddings: :environment do
    account_ids = ENV['ACCOUNT_IDS'].to_s.split(',').map(&:strip).reject(&:empty?).map(&:to_i).presence
    result = Autonomia::Agents::Knowledge::EmbeddingBackfiller.new(account_ids: account_ids).perform
    puts "[autonomia][backfill] accounts=#{result.accounts} embedded=#{result.embedded} " \
         "skipped=#{result.skipped} failed_accounts=#{result.failed_accounts.inspect}"
  end
end
