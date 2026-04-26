# CUSTOMIZAÇÃO_SYNAPSEOS — auto-cria os 7 AgentBots canônicos do Esquadrão
# Synapse, com `squadron_role` setado.
#
# Sem esses bots existindo, `AgentResolver.bots_for_slug` retorna vazio e:
#  - AgentMetrics card do papel não mostra KPIs
#  - LiveDashboard não mostra status do agente
#  - Labels emitidas pelo N8N/listener não têm "dono" atribuído
#
# Cada bot é criado sem `outgoing_url` (placeholder): o admin configura
# depois em Settings → Agent Bots → Edit, apontando pro webhook do N8N
# ou backend IA dele. O token de acesso é gerado automaticamente pelo
# AccessTokenable, e fica disponível via API.
#
# Idempotente: busca por `squadron_role` (scope unique por account via
# índice parcial) antes de criar.
class Synapseos::SquadronBotsSeeder
  SQUADRON = [
    { role: 'alice',    name: 'Alice',    description: 'Prospecção — BDR outbound. Caça leads frios e quebra o gelo.' },
    { role: 'iza',      name: 'Iza',      description: 'Recepção — SDR inbound. Triagem rápida de leads quentes.' },
    { role: 'luis',     name: 'Luís',     description: 'Especialista — Sales Pilot. Respostas técnicas via RAG em notas privadas.' },
    { role: 'otto',     name: 'Otto',     description: 'Auditoria — CRM + SLA. Cobra follow-ups e preenche Syonet.' },
    { role: 'fernanda', name: 'Fernanda', description: 'Resgate — reativação de base morta e leads perdidos.' },
    { role: 'angela',   name: 'Ângela',   description: 'Farming — pós-venda, LTV, cross-sell oficina × showroom.' },
    { role: 'vitor',    name: 'Vitor',    description: 'Recuperação — TechFin. Cobrança humanizada e PIX via WhatsApp.' }
  ].freeze

  def self.call(account)
    new(account).call
  end

  def initialize(account)
    @account = account
  end

  def call
    return unless AgentBot.column_names.include?('squadron_role')

    SQUADRON.each { |attrs| upsert_bot(attrs) }
  end

  private

  def upsert_bot(attrs)
    bot = @account.agent_bots.find_or_initialize_by(squadron_role: attrs[:role])
    bot.name = attrs[:name] if bot.name.blank?
    bot.description = attrs[:description] if bot.description.blank?
    bot.bot_type = :webhook
    bot.save!
  rescue StandardError => e
    Rails.logger.warn("[SquadronBotsSeeder] account #{@account.id} role #{attrs[:role]}: #{e.message}")
  end
end
