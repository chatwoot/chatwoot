class AddSquadronRoleToAgentBots < ActiveRecord::Migration[7.1]
  # CUSTOMIZAÇÃO_SYNAPSEOS: squadron_role classifica o AgentBot num dos 7 papéis
  # do Esquadrão Synapse (alice, iza, luis, otto, fernanda, angela, vitor). O
  # AgentResolver prioriza esse campo; fallback por nome mantém bots legados.
  def change
    add_column :agent_bots, :squadron_role, :string
    add_index :agent_bots, :squadron_role, where: 'squadron_role IS NOT NULL'
  end
end
