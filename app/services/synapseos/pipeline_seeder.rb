module Synapseos
  # Idempotente: cria os 7 stages padrão do pipeline SynapseOS para a conta.
  # Use `call(account)` do `Account.after_create` ou de migrations de backfill.
  #
  # Resistente a schema legado: detecta se a coluna `slug` existe (só depois
  # da migration 20260421235001) e usa `name` como chave de idempotência
  # quando não. Isso permite que o controller chame o seeder lazy sem
  # quebrar em produções que ainda não rodaram todas as migrations.
  class PipelineSeeder
    def self.call(account)
      new(account).call
    end

    def initialize(account)
      @account = account
    end

    def call
      # Preserva customizações: se a account já tem QUALQUER stage, assume
      # template customizado (audi_sdr, premium_luxo, etc.) e NÃO re-injeta
      # os defaults. Sem esse short-circuit, o `Pipeline#show` lazy-seed
      # repopula os 7 spin_generico por cima de qualquer template aplicado,
      # gerando duplicação (ex.: account Audi com 8 stages do template
      # acabava com 15 — 8 customizados + 7 spin_generico re-criados a cada
      # visita da página).
      return if ::Synapseos::PipelineStage.where(account_id: @account.id).exists?

      # Itera por TODOS os stages mesmo se um falhar — não queremos que um
      # erro de uniqueness no primeiro impeça os demais de existirem.
      ::Synapseos::PipelineStage::DEFAULT_STAGES.each do |attrs|
        upsert_stage(attrs)
      end
    end

    private

    def upsert_stage(attrs)
      stage = find_or_initialize(attrs)
      stage.assign_attributes(safe_attrs(attrs))
      stage.save!
    rescue StandardError => e
      Rails.logger.error(
        "[Synapseos::PipelineSeeder] account=#{@account.id} slug=#{attrs[:slug]} name=#{attrs[:name]} falhou: #{e.class} #{e.message}"
      )
    end

    def slug_supported?
      @slug_supported ||= ::Synapseos::PipelineStage.column_names.include?('slug')
    end

    def description_supported?
      @description_supported ||= ::Synapseos::PipelineStage.column_names.include?('description')
    end

    # Tenta achar primeiro por slug (chave estável), depois pelo nome —
    # cobre o caso onde a backfill migration renomeou os stages legados
    # mas o slug ficou nulo.
    def find_or_initialize(attrs)
      scope = ::Synapseos::PipelineStage.where(account_id: @account.id)

      if slug_supported?
        existing = scope.find_by(slug: attrs[:slug]) || scope.find_by(name: attrs[:name])
        return existing if existing

        scope.new(slug: attrs[:slug])
      else
        scope.find_or_initialize_by(name: attrs[:name])
      end
    end

    def safe_attrs(attrs)
      payload = attrs.merge(account_id: @account.id)
      payload = payload.except(:slug) unless slug_supported?
      payload = payload.except(:description) unless description_supported?
      payload
    end
  end
end
