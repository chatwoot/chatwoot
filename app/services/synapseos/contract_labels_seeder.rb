# CUSTOMIZAÇÃO_SYNAPSEOS — auto-seed das labels do contrato de tags.
#
# O contrato (docs/synapseos/tags_contract.md) define 12 labels que cada
# agente do esquadrão é responsável por aplicar/reagir. Sem as labels
# criadas, as queries de Dashboard/AgentMetrics retornam zero, porque
# elas dependem de `conversations.tagged_with(...)`.
#
# Cores alinhadas à paleta Dexi:
#   - cyan (accent): labels de fluxo geral (outbound, lead_qualificado)
#   - success/warning/error: semânticas (ganho / alerta / transbordo)
#   - tons neutros de apoio pra labels operacionais
#
# Idempotente: find_or_create_by por (title, account_id) unique.
class Synapseos::ContractLabelsSeeder
  CONTRACT = [
    { title: 'outbound',                 color: '#0E7490', description: 'Conversa iniciada ativamente pelo bot/BDR (Alice).' },
    { title: 'lead_novo_recepcionado',   color: '#00B8D9', description: 'Lead inbound recepcionado e triado pela Iza.' },
    { title: 'lead_qualificado',         color: '#1D7F56', description: 'Lead qualificado como oportunidade real.' },
    { title: 'crm_updated',              color: '#425466', description: 'CRM externo (Syonet) atualizado pelo Otto.' },
    { title: 'sla_alert',                color: '#9A6700', description: 'SLA ultrapassado — Otto alertou o atendente.' },
    { title: 'rescue_transbordo',        color: '#C53030', description: 'Transbordo de humano de volta pra bot (resgate).' },
    { title: 'assistencia_tecnica',      color: '#1A4272', description: 'Nota técnica gerada pelo Luís via RAG.' },
    { title: 'resgatado_fernanda',       color: '#1D7F56', description: 'Lead da base morta reativado pela Fernanda.' },
    { title: 'farming_revisao',          color: '#5B6B7A', description: 'Revisão agendada — ponto de farming da Ângela.' },
    { title: 'farming_crosssell',        color: '#0E7490', description: 'Cross-sell originado pela Ângela (pós-venda).' },
    { title: 'inadimplencia_contato',    color: '#9A6700', description: 'Contato de cobrança iniciado pelo Vitor.' },
    { title: 'inadimplencia_recuperada', color: '#1D7F56', description: 'Inadimplência recuperada com sucesso.' }
  ].freeze

  def self.call(account)
    new(account).call
  end

  def initialize(account)
    @account = account
  end

  def call
    CONTRACT.each { |attrs| upsert_label(attrs) }
  end

  private

  def upsert_label(attrs)
    label = @account.labels.find_or_initialize_by(title: attrs[:title])
    label.color = attrs[:color]
    label.description = attrs[:description] if label.description.blank?
    label.show_on_sidebar = false
    label.save!
  rescue StandardError => e
    Rails.logger.warn("[ContractLabelsSeeder] account #{@account.id} label #{attrs[:title]}: #{e.message}")
  end
end
