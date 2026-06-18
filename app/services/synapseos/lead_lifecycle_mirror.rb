module Synapseos
  # ADR-003 / I3 — espelhamento por construção.
  #
  # A cada transição, reflete o estado do lead no Chatwoot pra que o atendente
  # veja desfecho/troca/pagamento/urgência no painel da conversa — não só no
  # backend/Slack. É best-effort: o chamador (LeadLifecycle) já fez rescue, mas
  # cada passo também é defensivo pra que uma falha não aborte os demais.
  #
  # Reflete:
  #   - custom_attributes da conversa (estado + campos de negócio + retomada)
  #   - label de estado (remove o antigo, aplica o novo)
  #   - status da conversa (resolve SÓ no terminal nao_quer)
  #   - CrmEvent 'lead_state_changed' na timeline
  #
  # Idempotente: re-chamar com o mesmo estado não duplica CrmEvent nem
  # re-resolve a conversa.
  class LeadLifecycleMirror
    # Todas as labels de estado possíveis — usadas pra limpar antes de aplicar a
    # nova (um lead tem no máximo uma label de estado por vez).
    ESTADO_LABELS = {
      'quer' => 'lead:quer',
      'quer_depois' => 'lead:futuro',
      'nao_quer' => 'lead:encerrado',
      'sem_resposta' => 'lead:sem-resposta',
      'pos_venda' => 'lead:pos-venda',
      'outros' => 'lead:outros'
    }.freeze

    ALL_ESTADO_LABELS = ESTADO_LABELS.values.freeze

    def initialize(lead:, from_estado:, signal:)
      @lead = lead
      @from_estado = from_estado
      @signal = signal
    end

    def call
      @conversation = @lead.conversation
      return if @conversation.nil?

      mirror_custom_attributes
      mirror_label
      mirror_status
      mirror_crm_event
    end

    private

    def estado
      @lead.estado
    end

    def mirror_custom_attributes
      attrs = (@conversation.custom_attributes || {}).dup
      attrs['lead_estado'] = estado
      attrs['lead_modelo_interesse'] = @lead.modelo_interesse
      attrs['lead_tem_troca'] = @lead.tem_troca
      attrs['lead_forma_pagamento'] = @lead.forma_pagamento
      attrs['lead_urgencia'] = @lead.urgencia
      attrs['lead_retomada_at'] = @lead.retomada_at&.iso8601
      attrs.compact!

      @conversation.update_columns(custom_attributes: attrs) # rubocop:disable Rails/SkipsModelValidations
    rescue StandardError => e
      log_warn('custom_attributes', e)
    end

    def mirror_label
      target = ESTADO_LABELS[estado]
      current = @conversation.label_list
      # Remove qualquer label de estado antiga, preserva as demais.
      kept = current.reject { |l| ALL_ESTADO_LABELS.include?(l) }
      desired = (kept + [target].compact).uniq

      return if desired.sort == current.sort # idempotente: nada a fazer

      @conversation.update_labels(desired)
    rescue StandardError => e
      log_warn('label', e)
    end

    def mirror_status
      # Auto-resolve SÓ no terminal nao_quer (I1). Idempotente: não re-resolve.
      return unless estado == 'nao_quer'
      return if @conversation.resolved?

      @conversation.update!(status: :resolved)
    rescue StandardError => e
      log_warn('status', e)
    end

    def mirror_crm_event
      # Idempotente: se o estado não mudou, não registra evento duplicado.
      return if @from_estado == estado

      ::Synapseos::CrmEvent.create!(
        account_id: @lead.account_id,
        conversation_id: @lead.conversation_id,
        event_type: 'lead_state_changed',
        metadata: {
          from: @from_estado,
          to: estado,
          signal: @signal.to_s,
          motivo: @lead.motivo,
          retomada_at: @lead.retomada_at&.iso8601,
          next_action_at: @lead.next_action_at&.iso8601,
          cadence_touch: @lead.cadence_touch,
          modelo_interesse: @lead.modelo_interesse
        }.compact
      )
    rescue StandardError => e
      log_warn('crm_event', e)
    end

    def log_warn(step, error)
      Rails.logger.warn(
        "[Synapseos::LeadLifecycleMirror] #{step} mirror failed for lead=#{@lead.id}: #{error.class}: #{error.message}"
      )
    end
  end
end
