module Synapseos
  # Idempotente: popula os pipeline stages padrão se a conta ainda
  # não tiver nenhum. Chamado lazy pelos endpoints de pipeline.
  class EnsureDefaultStagesService
    def initialize(account)
      @account = account
    end

    def call
      return if ::Synapseos::PipelineStage.exists?(account_id: @account.id)

      ::Synapseos::PipelineStage::DEFAULT_STAGES.each do |attrs|
        ::Synapseos::PipelineStage.create!(attrs.merge(account_id: @account.id))
      end
    end
  end
end
