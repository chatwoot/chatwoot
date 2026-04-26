class AddSynapseosAgenticPanelUrlConfig < ActiveRecord::Migration[7.1]
  # Adiciona o config SYNAPSEOS_AGENTIC_PANEL_URL — URL pública (acessível pelo
  # browser) do painel agentic. Quando definido, o super_admin ganha um link
  # externo "Synapse Agentic Panel" que abre em nova aba.
  #
  # Diferença do SYNAPSEOS_AGENTIC_URL:
  # - URL = endereço usado pelo backend Rails para chamar a API agentic (pode
  #   ser interno: http://agentic:8000 num docker-compose; ou externo).
  # - PANEL_URL = endereço onde o browser do super_admin chega no painel UI;
  #   precisa ser público + HTTPS em prod.
  #
  # Os dois podem ser iguais quando o agentic está atrás do mesmo Caddy do
  # Chatwoot (ex: chatwoot.cliente.com.br/_agentic/).
  def up
    return if InstallationConfig.exists?(name: 'SYNAPSEOS_AGENTIC_PANEL_URL')

    InstallationConfig.create!(name: 'SYNAPSEOS_AGENTIC_PANEL_URL', value: nil, locked: false)
  end

  def down
    InstallationConfig.where(name: 'SYNAPSEOS_AGENTIC_PANEL_URL').destroy_all
  end
end
