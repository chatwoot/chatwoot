namespace :autonomia do
  # Backfill RE-EMBED-ONLY do embedding_large (3-large/halfvec) na base Autônoma existente. Fase 1 do
  # cutover big-bang p/ 3-large, SEM regressão (não deleta, não re-chunka; a coluna 3-small segue
  # servindo até o flip). Idempotente/resumível. NÃO faz o cutover — após validar as contagens, o flip
  # é manual: InstallationConfig AUTONOMIA_EMBEDDING_MODEL=text-embedding-3-large.
  #
  # Operação Vermelha, segurança embutida no código (não em disciplina de copy-paste):
  #   - PREFLIGHT read-only: emite snapshot {accounts,pending} no stdout (capturado no log; /tmp some no
  #     container --rm, por isso stdout).
  #   - ABORT-SE-ZERO: pending=0 => sai 0 sem tocar OpenAI (nada a fazer).
  #   - COUNT_ONLY=1: dry-run — só o preflight, nunca embeda.
  #   - EXIT 1 se alguma conta falhar (credencial/provedor) => sinaliza reprocessar.
  #
  #   COUNT_ONLY=1 bundle exec rails autonomia:backfill_large_embeddings                 # dry-run global
  #   ACCOUNT_IDS=3 bundle exec rails autonomia:backfill_large_embeddings                # onda 1 (conta 3)
  #   bundle exec rails autonomia:backfill_large_embeddings                              # toda a base
  desc 'Preenche embedding_large (3-large/halfvec) nos KnowledgeEntry existentes (re-embed-only, no-regression)'
  task backfill_large_embeddings: :environment do
    account_ids = ENV['ACCOUNT_IDS'].to_s.split(',').map(&:strip).reject(&:empty?).map(&:to_i).presence
    backfiller = Autonomia::Agents::Knowledge::EmbeddingBackfiller.new(account_ids: account_ids)

    preview = backfiller.preview
    puts "[autonomia][backfill][preflight] accounts=#{preview.accounts} pending=#{preview.pending} " \
         "model=#{Autonomia::Agents::Config::EMBEDDING_MODEL_LARGE} account_ids=#{account_ids.inspect}"

    if ENV['COUNT_ONLY'].present?
      puts '[autonomia][backfill] COUNT_ONLY=1 — dry-run, nada embedado.'
      next
    end

    if preview.pending.zero?
      puts '[autonomia][backfill] pending=0 — nada a fazer (abort-se-zero). Nenhuma chamada ao provedor.'
      next
    end

    result = backfiller.perform
    puts "[autonomia][backfill][done] accounts=#{result.accounts} embedded=#{result.embedded} " \
         "skipped=#{result.skipped} failed_accounts=#{result.failed_accounts.inspect}"

    if result.failed_accounts.any?
      abort "[autonomia][backfill] FALHA em #{result.failed_accounts.size} conta(s): " \
            "#{result.failed_accounts.inspect} — corrija a credencial e re-rode (resumível)."
    end
  end
end
