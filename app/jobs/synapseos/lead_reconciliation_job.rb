module Synapseos
  # ADR-003 / Fase 3 — sweeper de reconciliação (a rede de segurança).
  #
  # Filosofia "não confia, verifica e conserta": varre os leads e REPARA
  # violações de invariante, em vez de só alertar. Conserta:
  #
  #   - Lead não-terminal sem next_action_at OU com next_action_at no passado
  #     (lead "largado" / dormente) -> transition(:sem_resposta_esgotou),
  #     reentrando em Futuro + 90d. Mata a dormência silenciosa (I2).
  #   - Lead terminal nao_quer cuja conversa ainda está open -> resolve (I1).
  #
  # Emite Rails.logger.info com a contagem de violações reparadas (métrica;
  # meta: 0). Retorna a contagem.
  #
  # Agendamento: registrado em config/schedule.yml como
  # `synapseos_lead_reconciliation_job` (diário, baixa traffic). O mecanismo de
  # cron deste repo é sidekiq-cron lendo config/schedule.yml.
  class LeadReconciliationJob < ApplicationJob
    queue_as :scheduled_jobs

    def perform
      i2_repaired = repair_missing_next_action
      i1_repaired = repair_unresolved_terminal

      total = i2_repaired + i1_repaired
      Rails.logger.info(
        '[Synapseos::LeadReconciliationJob] reconciliation done: ' \
        "i2_missing_next_action=#{i2_repaired} i1_unresolved_terminal=#{i1_repaired} total_violations=#{total}"
      )
      total
    end

    private

    # I2: lead num estado não-terminal cujo próximo passo está ausente ou já
    # venceu. Só o caso INEQUÍVOCO do ADR (silêncio com cadência esgotada) é
    # reparado automaticamente pra Futuro + 90d. Um lead 'quer' (SLA do consultor
    # estourou) ou 'quer_depois' (retomada venceu sem re-toque) NÃO é rebaixado
    # pra nutrição silenciosamente — é caso de escalação/decisão, então vira
    # violação LOGADA pra revisão (a métrica fica visível, sem esfriar um lead
    # quente).
    def repair_missing_next_action
      count = 0
      flagged = 0
      candidates.find_each do |lead|
        next if lead.estado.blank? # legado, fora da máquina
        next if lead.terminal?
        next unless next_action_violated?(lead)

        if lead.estado == 'sem_resposta'
          ::Synapseos::LeadLifecycle.transition(lead: lead, signal: :sem_resposta_esgotou)
          count += 1
        else
          flagged += 1
          Rails.logger.warn(
            "[Synapseos::LeadReconciliationJob] lead=#{lead.id} estado=#{lead.estado} " \
            "next_action_at=#{lead.next_action_at.inspect} vencido — sem repair automático (revisar/escalar)"
          )
        end
      rescue StandardError => e
        Rails.logger.error("[Synapseos::LeadReconciliationJob] failed to repair lead=#{lead.id}: #{e.class}: #{e.message}")
      end
      Rails.logger.info("[Synapseos::LeadReconciliationJob] next_action flagged_for_review=#{flagged}") if flagged.positive?
      count
    end

    # I1: lead terminal nao_quer cuja conversa ainda está open -> resolve.
    def repair_unresolved_terminal
      count = 0
      ::Synapseos::Lead.where(estado: 'nao_quer').includes(:conversation).find_each do |lead|
        conv = lead.conversation
        next if conv.nil? || conv.resolved?

        conv.update!(status: :resolved)
        count += 1
      rescue StandardError => e
        Rails.logger.error("[Synapseos::LeadReconciliationJob] failed to resolve conv for lead=#{lead.id}: #{e.class}: #{e.message}")
      end
      count
    end

    def candidates
      ::Synapseos::Lead.where.not(estado: nil)
    end

    def next_action_violated?(lead)
      lead.next_action_at.nil? || lead.next_action_at < Time.current
    end
  end
end
