# Reaper de rascunhos ÓRFÃOS do Construtor. Causa-raiz do vazamento que o KB-first (§9) introduz: com
# opt-in de base o rascunho nasce ANTES do chat (para a etapa de anexar materiais ter agentId), então
# abrir o Construtor e sair deixa um agente "Novo agente" vazio pendurado no Hub. Também limpa o leak
# pré-existente (rascunhos abandonados após o 1º turno), que nunca teve cleanup.
#
# Varre agentes GUIADOS ainda em `draft` + `enabled:false` cuja última atividade — do próprio agente E
# de TODAS as suas build threads — é mais velha que a janela, e os destrói (cascateando
# sources/knowledge_entries via dependent: :destroy; threads viram nil por dependent: :nullify).
# Escopo estreito (guided + draft + disabled) nunca toca agente ativo/pausado ou manual.
#
# Janela ampla (48h default, ajustável por ENV) protege rascunho em construção lenta: qualquer
# geração/edição/upload toca o updated_at do agente ou da thread e reabre a janela. Idempotente;
# cap por execução evita pico de exclusão. Roda de tempos em tempos (schedule.yml).
class Autonomia::Agents::ReapStaleDraftsJob < ApplicationJob
  queue_as :scheduled_jobs

  DEFAULT_STALE_HOURS = 48
  BATCH_LIMIT = 500

  def perform
    cutoff = stale_hours.hours.ago
    reaped = stale_drafts(cutoff).limit(BATCH_LIMIT).count(&:destroy!)
    return unless reaped.positive?

    Rails.logger.info("[Autonomia::ReapStaleDrafts] reaped=#{reaped} cutoff=#{cutoff.iso8601}")
  end

  private

  # Rascunhos guiados órfãos: draft + desabilitado + sem atividade recente (nem do agente nem de
  # qualquer thread sua) dentro da janela.
  def stale_drafts(cutoff)
    active_thread_agent_ids = Autonomia::Agents::BuildThread
                              .where('updated_at >= ?', cutoff)
                              .select(:autonomia_agent_id)
    Autonomia::Agents::Agent
      .guided.draft.where(enabled: false)
      .where('autonomia_agents.updated_at < ?', cutoff)
      .where.not(id: active_thread_agent_ids)
  end

  def stale_hours
    Integer(ENV.fetch('AUTONOMIA_DRAFT_REAP_HOURS', DEFAULT_STALE_HOURS))
  rescue ArgumentError, TypeError
    DEFAULT_STALE_HOURS
  end
end
