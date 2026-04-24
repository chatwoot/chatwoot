class BackfillSynapseosDefaults < ActiveRecord::Migration[7.1]
  # CUSTOMIZAÇÃO_SYNAPSEOS — garante labels do contrato + AgentBots do
  # esquadrão em toda conta existente. Contas antigas (antes do
  # AccountDefaults hook) nunca receberam esses seeds.
  # Idempotente: seeders fazem find_or_* interno.
  disable_ddl_transaction!

  def up
    Account.find_each do |account|
      ::Synapseos::ContractLabelsSeeder.call(account)
      ::Synapseos::SquadronBotsSeeder.call(account)
    rescue StandardError => e
      Rails.logger.warn("[SynapseosBackfill] account #{account.id} falhou: #{e.message}")
    end
  end

  def down
    # Não desfaz — remover labels poderia apagar tags aplicadas em produção;
    # remover bots poderia afetar mensagens existentes (nullify).
  end
end
