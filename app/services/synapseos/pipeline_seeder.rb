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
      ::Synapseos::PipelineStage::DEFAULT_STAGES.each do |attrs|
        stage = find_or_initialize(attrs)
        stage.assign_attributes(safe_attrs(attrs))
        stage.save!
      end
    rescue StandardError => e
      Rails.logger.warn("[Synapseos::PipelineSeeder] account #{@account.id} falhou: #{e.message}")
    end

    private

    def slug_supported?
      @slug_supported ||= ::Synapseos::PipelineStage.column_names.include?('slug')
    end

    def description_supported?
      @description_supported ||= ::Synapseos::PipelineStage.column_names.include?('description')
    end

    def find_or_initialize(attrs)
      scope = ::Synapseos::PipelineStage.where(account_id: @account.id)
      if slug_supported?
        scope.find_or_initialize_by(slug: attrs[:slug])
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
