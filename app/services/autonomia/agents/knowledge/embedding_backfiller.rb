module Autonomia
  module Agents
    module Knowledge
      # Backfill RE-EMBED-ONLY (B1 Onda 6) — preenche `embedding_large` (text-embedding-3-large @ 3072
      # dims, halfvec) nos KnowledgeEntry JÁ existentes, SEM deletar nem re-chunkar. A coluna legada
      # `embedding` (vector 1536, 3-small) segue servindo o retrieval até o cutover explícito
      # (InstallationConfig AUTONOMIA_EMBEDDING_MODEL=text-embedding-3-large) — logo NÃO há janela de
      # retrieval vazio (sem regressão). É a fase 1 do plano big-bang: reprocessa a base toda de uma vez;
      # os chunks/metadata do B2 só chegam depois, na re-ingestão natural das fontes (pós-cutover).
      #
      # IDEMPOTENTE/RESUMÍVEL: só toca linhas com `embedding_large IS NULL` — re-rodar continua de onde
      # parou. POR CONTA: cada conta tem sua chave OpenAI (EmbeddingService via CredentialResolver);
      # conta sem credencial/válida é PULADA com aviso (não derruba o backfill das outras). NUNCA deleta.
      class EmbeddingBackfiller
        BATCH_SIZE = 200
        MODEL = Config::EMBEDDING_MODEL_LARGE

        Result = Struct.new(:accounts, :embedded, :skipped, :failed_accounts, keyword_init: true)

        def initialize(logger: Rails.logger, account_ids: nil)
          @logger = logger
          @account_ids = account_ids
        end

        # Percorre as contas com conhecimento Autônomo e embeda-em-lote o que falta. Devolve um Result
        # com as contagens (accounts/embedded/skipped/failed_accounts) p/ o operador validar o big-bang.
        def perform
          result = Result.new(accounts: 0, embedded: 0, skipped: 0, failed_accounts: [])
          account_scope.find_each do |account|
            result.accounts += 1
            backfill_account(account, result)
          end
          @logger.info("[autonomia][backfill] done accounts=#{result.accounts} embedded=#{result.embedded} " \
                       "skipped=#{result.skipped} failed_accounts=#{result.failed_accounts}")
          result
        end

        private

        def account_scope
          scope = Account.where(id: KnowledgeEntry.select(:account_id).distinct)
          @account_ids.present? ? scope.where(id: @account_ids) : scope
        end

        # Erro de credencial/provedor da conta NÃO derruba o backfill: pula a conta e segue (o operador
        # corrige a credencial e re-roda — como é resumível, só as faltantes serão reprocessadas).
        def backfill_account(account, result)
          service = EmbeddingService.new(account: account, model: MODEL)
          pending_entries(account).find_in_batches(batch_size: BATCH_SIZE) do |batch|
            embed_batch(service, batch, result)
          end
        rescue EmbeddingService::EmbeddingError => e
          @logger.warn("[autonomia][backfill] account=#{account.id} embedding error #{e.class} — skipping")
          result.failed_accounts << account.id
        end

        def pending_entries(account)
          KnowledgeEntry.where(account_id: account.id, embedding_large: nil)
        end

        def embed_batch(service, batch, result)
          vectors = service.embed_batch(batch.map(&:content))
          batch.each_with_index do |entry, index|
            vector = vectors[index]
            if vector.blank?
              result.skipped += 1
              next
            end
            write_large_embedding!(entry, vector)
            result.embedded += 1
          end
        end

        # halfvec via update_all sanitizado (literal "[...]" + cast) — a gem neighbor não casta halfvec.
        # NÃO toca a coluna legada `embedding` nem deleta nada (re-embed puro, sem regressão).
        def write_large_embedding!(entry, vector)
          KnowledgeEntry.where(id: entry.id)
                        .update_all(['embedding_large = ?::halfvec', "[#{vector.join(',')}]"]) # rubocop:disable Rails/SkipsModelValidations
        end
      end
    end
  end
end
