module Autonomia
  module Agents
    class BuildThread < ApplicationRecord
      self.table_name = 'autonomia_agent_build_threads'

      belongs_to :account
      belongs_to :agent, class_name: 'Autonomia::Agents::Agent',
                         foreign_key: :autonomia_agent_id, optional: true
      belongs_to :created_by, class_name: 'User', optional: true

      enum status: { open: 0, processing: 1, ready: 2, failed: 3 }

      store_accessor :state, :draft_config, :needs_more_info, :next_question, :turn
      # Revisor v2 / portão de materiais: o usuário declarou que NÃO tem material para subir (avançou
      # a etapa de materiais sem anexar nada). O controller grava isso quando o front manda
      # `no_materials: true`; o Builder usa no portão de conclusão (materials_pending?) para deixar a
      # instrução fechar mesmo sem nenhuma fonte revisada.
      store_accessor :state, :no_materials_declared
      # #3 INSTRUÇÃO VIVA (auto-finalize): o usuário avançou da etapa Conversa/Materiais para a Revisão
      # sem ter fechado a conversa. O controller grava `force_close: true` quando o front manda
      # `force_close: true`; o Builder usa em force_close? para FORÇAR o fechamento (needs_more_info=false)
      # de forma DETERMINÍSTICA e INDEPENDENTE DE IDIOMA — sem depender do match da frase de fechamento.
      store_accessor :state, :force_close
      # IA-FALA-PRIMEIRO (item 3): tipo de agente escolhido na abertura, persistido no jsonb `state`
      # ANTES de existir um agente-rascunho. Alimenta Builder#builder_agent_type (esqueleto por tipo e
      # 1º turno) enquanto @thread.agent ainda é nil.
      store_accessor :state, :agent_type
      # V2.1 — escolhas da abertura: atuação (external/internal/both) e se terá base de conhecimento.
      # Persistidas no jsonb `state` ANTES de existir o agente-rascunho; o Builder lê via
      # builder_actuation / with_knowledge?. with_knowledge=false também semeia no_materials_declared.
      store_accessor :state, :actuation, :with_knowledge

      # Persiste o tipo escolhido na abertura, normalizando para os AGENT_TYPES válidos (desconhecido →
      # 'custom'). Só grava quando vem um valor; chamado pelo controller no create da thread.
      def persist_agent_type!(type)
        return if type.blank?

        valid = Autonomia::Agents::Agent::AGENT_TYPES.include?(type) ? type : 'custom'
        self.state = (state || {}).merge('agent_type' => valid)
      end

      ACTUATIONS = %w[external internal both].freeze

      # V2.1 — grava as escolhas da abertura (tipo + atuação + base) num único merge no jsonb `state`.
      # `actuation` normaliza para um valor válido (fallback external = comportamento atual);
      # `with_knowledge=false` também semeia `no_materials_declared` para reusar o portão sem-material
      # do Builder (não pedir documentos no 1º turno). Valores ausentes mantêm os defaults de hoje.
      def persist_start_options!(type:, actuation: nil, with_knowledge: nil)
        persist_agent_type!(type)
        merged = (state || {}).dup

        merged['actuation'] = ACTUATIONS.include?(actuation.to_s) ? actuation.to_s : 'external' unless actuation.nil?

        # with_knowledge=false NÃO semeia no_materials_declared: aquele flag é o portão de FECHAMENTO
        # ("sem material, feche") e fecharia o build no 1º turno sem coletar o essencial. A orientação de
        # não pedir documentos vem do Builder#knowledge_intent_context (bloco persistente), preservando a
        # entrevista normal. with_knowledge só registra a intenção (refletida no config do agente).
        merged['with_knowledge'] = ActiveModel::Type::Boolean.new.cast(with_knowledge) unless with_knowledge.nil?

        self.state = merged
      end

      # E3 — janela de "geração presa": o SubmitJob é síncrono e leva segundos; se a thread ficou
      # `processing` por mais tempo que isto, o job morreu/perdeu-se sem mark_failed! (o token-guard
      # impede qualquer escrita posterior). Passada a janela, reenvio/retry pode reassumir com um
      # novo token; dentro dela, um novo turno é rejeitado (custo duplo + supersede do turno vivo).
      STALE_PROCESSING_AFTER = 5.minutes

      # E3 — há um build vivo agora? (processing e ainda dentro da janela esperada do job).
      def build_in_progress?
        processing? && !build_stale?
      end

      # E3 — build preso: processing além da janela do SubmitJob (updated_at é tocado por
      # begin_build!, então mede o início da geração ativa).
      def build_stale?
        processing? && updated_at < STALE_PROCESSING_AFTER.ago
      end

      # token-guard da geração do construtor (padrão EmailCampaign#ai_begin!): marca processing +
      # novo build_token. Toda escrita posterior (mark_ready!/mark_failed!) só vence se o token ainda
      # for o ativo E o status ainda for processing. Retorna o token p/ o SubmitJob/PollJob.
      #
      # CLAIM ATÔMICO (T6 review): um único UPDATE guardado por WHERE decide quem inicia a geração —
      # só vence se o status estiver fora de processing OU o processing estiver preso além da janela
      # stale. Duas chamadas simultâneas nunca vencem juntas: a perdedora recebe nil (o controller
      # responde 409) sem turno nem job duplicado. Fecha a janela check-then-act do antigo
      # `build_in_progress?` + update incondicional.
      def begin_build!
        token = SecureRandom.hex(16)
        claimed = self.class.where(id: id)
                      .where('status <> :processing OR updated_at < :stale_before',
                             processing: self.class.statuses[:processing],
                             stale_before: STALE_PROCESSING_AFTER.ago)
                      .update_all(status: self.class.statuses[:processing], build_token: token,
                                  updated_at: Time.current)
        return nil if claimed.zero?

        reload
        token
      end

      def mark_ready!(token, state:)
        # MERGE (não substitui): preserva chaves do jsonb `state` que o Builder.state_for não
        # reemite — em especial `no_materials_declared` (gravada uma única vez pelo controller).
        # Sem o merge, a 1ª geração após a declaração "não tenho material" zerava a flag e o portão
        # de materiais voltava a travar o fechamento da instrução (caminho feliz preso).
        new_state = (self.state || {}).merge(state)
        guarded_update(token, status: self.class.statuses[:ready], state: new_state)
      end

      def mark_failed!(token, message)
        new_state = (self.state || {}).merge('error' => message.to_s.truncate(500))
        guarded_update(token, status: self.class.statuses[:failed], state: new_state)
      end

      # push de uma mensagem no jsonb `messages` ([{role, content, at}]). Sem token-guard: é a
      # entrada do usuário/assistente na conversa, não uma transição de geração.
      # MULTIMODAL (aditivo): `image_signed_ids` opcional guarda as referências ActiveStorage das imagens
      # anexadas a ESTE turno; default [] preserva o shape legado {role,content,at} (sem regressão). O
      # Builder resolve as imagens só do último turno user (Builder#image_parts_for).
      def append_message!(role, content, image_signed_ids: [], client_message_id: nil)
        cid = client_message_id.to_s.presence
        # #17 — IDEMPOTÊNCIA (best-effort): se este turno já foi gravado com o mesmo client_message_id
        # (double-click / retry do front), é no-op — evita turno duplicado. Sem id (legado) não dedup.
        reload if cid
        return if cid && Array(messages).any? { |m| m['cid'] == cid }

        entry = { 'role' => role, 'content' => content.to_s, 'at' => Time.current.iso8601 }
        ids = Array(image_signed_ids).map(&:to_s).compact_blank
        entry['image_signed_ids'] = ids if ids.any?
        entry['cid'] = cid if cid
        # #17 — APPEND ATÔMICO no banco (jsonb `||` concatena; COALESCE cobre messages NULL). Substitui
        # o read-modify-write em Ruby (`messages = (messages||[]) + [entry]`), que sob concorrência
        # (2 abas / requests simultâneos) sobrescrevia o array inteiro e PERDIA mensagens (lost-update).
        self.class.where(id: id).update_all(
          ['messages = COALESCE(messages, \'[]\'::jsonb) || ?::jsonb, updated_at = ?', [entry].to_json, Time.current]
        )
        reload
      end

      private

      # Escreve só se a geração identificada por `token` ainda for a ativa e ainda processing.
      # update_all atômico fecha a janela entre checagem e escrita. Retorna true se ganhou (1 linha).
      def guarded_update(token, attrs)
        return false if token.blank?

        rows = self.class.where(id: id, build_token: token, status: self.class.statuses[:processing])
                   .update_all(attrs.merge(updated_at: Time.current))
        reload if rows.positive?
        rows.positive?
      end
    end
  end
end
