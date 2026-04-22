module Synapseos
  # Idempotente: popula os pipeline stages padrão se a conta ainda
  # não tiver nenhum. Chamado lazy pelos endpoints de pipeline.
  # Delega para `Synapseos::PipelineSeeder` (fonte de verdade dos stages padrão).
  class EnsureDefaultStagesService
    def initialize(account)
      @account = account
    end

    def call
      ::Synapseos::PipelineSeeder.call(@account)
    end
  end
end
