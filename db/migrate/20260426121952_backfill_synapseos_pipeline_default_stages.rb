class BackfillSynapseosPipelineDefaultStages < ActiveRecord::Migration[7.1]
  # Garante que todas as accounts existentes tenham os 7 stages SPIN default.
  # Migrations anteriores (20260426002000, 20260426002001) adicionaram a coluna
  # `description` e renomearam slugs antigos, mas accounts criadas antes do
  # PR do template SPIN podem ter ficado com 5 stages renomeados ou com 0
  # stages, sem que `lazy seeding` tivesse a chance de rodar (rota /pipeline
  # nunca acessada).
  #
  # Idempotente: executa o `Synapseos::PipelineSeeder` (que faz find_or_init
  # por slug, com fallback por nome) em cada account.
  def up
    return unless table_exists?(:synapseos_pipeline_stages)
    return unless column_exists?(:synapseos_pipeline_stages, :slug)

    Account.find_each do |account|
      ::Synapseos::PipelineSeeder.call(account)
    rescue StandardError => e
      Rails.logger.error(
        "[Backfill SPIN stages] account=#{account.id} falhou: #{e.class} #{e.message}"
      )
    end
  end

  def down
    # Não reverte — os stages são dados de domínio.
  end
end
