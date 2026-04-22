module Synapseos
  # Idempotente: cria os 5 stages padrão do pipeline SynapseOS para a conta.
  # Use `call(account)` do `Account.after_create` ou de migrations de backfill.
  class PipelineSeeder
    def self.call(account)
      new(account).call
    end

    def initialize(account)
      @account = account
    end

    def call
      ::Synapseos::PipelineStage::DEFAULT_STAGES.each do |attrs|
        stage = ::Synapseos::PipelineStage.find_or_initialize_by(account_id: @account.id, slug: attrs[:slug])
        stage.assign_attributes(attrs.merge(account_id: @account.id))
        stage.save!
      end
    end
  end
end
