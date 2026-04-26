class BackfillPipelineDefaultStages < ActiveRecord::Migration[7.1]
  # CUSTOMIZAÇÃO_SYNAPSEOS: garante que toda account existente tenha os 5
  # pipeline stages default (novo_lead, qualificado, negociação, fechado,
  # perdido). Contas antigas (criadas antes do AccountDefaults hook) nunca
  # rodaram o seed — sem stages, a UI do Pipeline fica vazia.
  #
  # Idempotente: PipelineSeeder usa find_or_initialize_by por slug; contas
  # que já têm stages não são afetadas.
  def up
    Account.find_each do |account|
      ::Synapseos::PipelineSeeder.call(account)
    rescue StandardError => e
      Rails.logger.warn("[PipelineBackfill] account #{account.id} falhou: #{e.message}")
    end
  end

  def down
    # Não desfaz — remover seeds padrão depois de aplicados seria destrutivo
    # para leads já associados.
  end
end
