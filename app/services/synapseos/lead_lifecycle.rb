module Synapseos
  # ADR-003 — coração da máquina de estados de lead.
  #
  # `synapseos_leads` é a fonte única de verdade do estado. ESTE serviço é o
  # ÚNICO ponto que muda estado. A transição é TOTAL (todo sinal cai em
  # exatamente um estado e sempre define next_action_at, ou um terminal com
  # motivo) e IDEMPOTENTE (chamar com o mesmo signal+attrs duas vezes não
  # duplica efeitos: não cria CrmEvent duplicado nem re-resolve a conversa).
  #
  # Uso:
  #   Synapseos::LeadLifecycle.transition(lead: lead, signal: :quer, modelo_interesse: 'A4')
  #
  # Sinais aceitos:
  #   :quer                  -> quer        (aguardando atendimento humano; SLA)
  #   :quer_depois           -> quer_depois (Futuro; retomada por horizonte)
  #   :nao_quer              -> nao_quer    (terminal; exige motivo; auto-resolve)
  #   :sem_resposta_toque    -> sem_resposta(cadência ++; agenda próximo toque)
  #   :sem_resposta_esgotou  -> sem_resposta (Encerrado + retomada 90d)
  class LeadLifecycle
    class InvalidSignal < StandardError; end
    class MotivoRequired < StandardError; end

    SIGNALS = %i[quer quer_depois nao_quer sem_resposta_toque sem_resposta_esgotou pos_venda outros].freeze

    # SLA padrão até escalar o estado "quer" se o consultor não pegar.
    # Configurável via ENV pra calibrar sem deploy.
    QUER_SLA = (ENV['SYNAPSEOS_QUER_SLA_HOURS'].presence&.to_f || 2).hours

    # Cadência esgotada -> reentra em Futuro com data longa. Nunca terminal por
    # silêncio (ADR-003).
    ESGOTOU_OFFSET = 90.days

    # Intervalo default entre toques de cadência quando o chamador não passa
    # next_action_at explícito. Espelha a cadência n8n (1h, 1d, 3d, 7d, 21d) de
    # forma simplificada: cresce com o toque.
    CADENCE_OFFSETS = [1.hour, 1.day, 3.days, 7.days, 21.days].freeze

    # Baldes de horizonte de compra -> offset de retomada (Futuro).
    # Regra (2026-08-25, conv 330): retomar no LIMITE INFERIOR do balde, não no
    # meio. Cliente que 'troca em outubro' (~60d, balde 1-3m) era retomado em
    # +2 meses = depois de já ter comprado. O consultor precisa do lead ANTES
    # da decisão, não durante. Espelhado no n8n (schedule_followup.json).
    HORIZONTE_OFFSETS = {
      'imediato' => nil,
      '1-3m' => 1.month,
      '3-6m' => 3.months,
      '6-12m' => 6.months,
      '+12m' => 12.months
    }.freeze

    # Slugs de stage usados pela máquina (criados sob demanda pelo template
    # audi_sdr). Se a account não os tiver, a transição não falha — só não move
    # o stage (best-effort, igual ao espelhamento).
    STAGE_QUER = 'aguardando_atendimento_humano'.freeze
    STAGE_FUTURO = 'futuro'.freeze
    STAGE_ENCERRADO = 'encerrado'.freeze
    STAGE_POS_VENDA = 'pos_venda'.freeze
    STAGE_OUTROS = 'outros'.freeze

    BUSINESS_FIELDS = %i[modelo_interesse tem_troca forma_pagamento urgencia horizonte_compra].freeze

    def self.transition(lead:, signal:, **attrs)
      new(lead: lead, signal: signal.to_sym, attrs: attrs).call
    end

    def initialize(lead:, signal:, attrs: {})
      @lead = lead
      @signal = signal
      @attrs = attrs.symbolize_keys
    end

    def call
      raise InvalidSignal, "sinal desconhecido: #{@signal.inspect}" unless SIGNALS.include?(@signal)

      from_estado = @lead.estado

      ActiveRecord::Base.transaction do
        persist_business_fields
        apply_signal
        @lead.save!
      end

      mirror!(from_estado)
      @lead
    end

    private

    def persist_business_fields
      BUSINESS_FIELDS.each do |field|
        @lead[field] = @attrs[field] unless @attrs[field].nil?
      end
    end

    def apply_signal
      case @signal
      when :quer then apply_quer
      when :quer_depois then apply_quer_depois
      when :nao_quer then apply_nao_quer
      when :sem_resposta_toque then apply_sem_resposta_toque
      when :sem_resposta_esgotou then apply_sem_resposta_esgotou
      when :pos_venda then apply_atendimento_humano('pos_venda', STAGE_POS_VENDA)
      when :outros then apply_atendimento_humano('outros', STAGE_OUTROS)
      end
    end

    def apply_quer
      @lead.estado = 'quer'
      move_to_stage(STAGE_QUER)
      @lead.status = :qualified
      @lead.qualified_at ||= now
      @lead.retomada_at = nil
      @lead.motivo = nil
      @lead.next_action_at = now + QUER_SLA
    end

    def apply_quer_depois
      @lead.estado = 'quer_depois'
      move_to_stage(STAGE_FUTURO)
      @lead.status = :open
      offset = HORIZONTE_OFFSETS.fetch(@lead.horizonte_compra, nil)
      @lead.retomada_at = offset ? now + offset : now
      @lead.motivo = nil
      @lead.next_action_at = @lead.retomada_at
    end

    def apply_nao_quer
      motivo = @attrs[:motivo].presence || @lead.motivo.presence
      raise MotivoRequired, 'motivo é obrigatório para o desfecho :nao_quer (I1)' if motivo.blank?

      @lead.estado = 'nao_quer'
      @lead.motivo = motivo
      move_to_stage(STAGE_ENCERRADO)
      @lead.status = :disqualified
      @lead.disqualified_at ||= now
      @lead.next_action_at = nil # terminal
    end

    def apply_sem_resposta_toque
      @lead.estado = 'sem_resposta'
      touch = @attrs[:cadence_touch].presence&.to_i || (@lead.cadence_touch.to_i + 1)
      @lead.cadence_touch = touch
      @lead.status = :open
      @lead.motivo = nil
      @lead.next_action_at = @attrs[:next_action_at].presence || (now + next_cadence_offset(touch))
    end

    def apply_sem_resposta_esgotou
      # SILÊNCIO NÃO É INTENÇÃO (corrigido 2026-08-16). Antes o lead que não
      # respondia a NENHUM toque virava estado 'quer_depois' e caía na coluna
      # Futuro — misturando quem sumiu com quem DISSE que troca mais pra frente.
      # A coluna Futuro é de intenção declarada; o próprio pipeline define
      # Encerrado como "sem resposta após cadência completa".
      # O lead NÃO é perdido: retomada_at segue em +90d pra reengajamento, e o
      # estado 'sem_resposta' preserva a verdade do que aconteceu.
      @lead.estado = 'sem_resposta'
      move_to_stage(STAGE_ENCERRADO)
      @lead.status = :disqualified
      @lead.disqualified_at ||= now
      @lead.motivo = 'sem_resposta_cadencia_esgotada'
      @lead.retomada_at = now + ESGOTOU_OFFSET
      @lead.next_action_at = @lead.retomada_at
    end

    # pos_venda / outros: cliente precisa de uma PESSOA mas NÃO é venda. O
    # roteamento pro humano continua sendo feito pelo webhook do n8n; aqui só
    # registramos o estado + SLA (não-terminal, precisa de atendimento). Stage é
    # best-effort (slug pode não existir na account).
    def apply_atendimento_humano(estado, stage_slug)
      @lead.estado = estado
      move_to_stage(stage_slug)
      @lead.status = :open
      @lead.retomada_at = nil
      @lead.motivo = nil
      @lead.next_action_at = now + QUER_SLA
    end

    # toque 1 -> CADENCE_OFFSETS[0], etc. Estoura -> usa o último (21d).
    def next_cadence_offset(touch)
      idx = (touch - 1).clamp(0, CADENCE_OFFSETS.size - 1)
      CADENCE_OFFSETS[idx]
    end

    def move_to_stage(slug)
      stage = find_stage(slug)
      @lead.pipeline_stage_id = stage.id if stage
    end

    def find_stage(slug)
      return nil unless ::Synapseos::PipelineStage.column_names.include?('slug')

      ::Synapseos::PipelineStage.find_by(account_id: @lead.account_id, slug: slug)
    end

    def mirror!(from_estado)
      ::Synapseos::LeadLifecycleMirror.new(
        lead: @lead,
        from_estado: from_estado,
        signal: @signal
      ).call
    rescue StandardError => e
      # I3 é best-effort na borda: o espelhamento NUNCA pode quebrar a
      # transição (que já está persistida). Loga e segue.
      Rails.logger.error("[Synapseos::LeadLifecycle] mirror failed for lead=#{@lead.id}: #{e.class}: #{e.message}")
    end

    def now
      @now ||= Time.current
    end
  end
end
