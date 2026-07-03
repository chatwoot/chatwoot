module Autonomia
  module Agents
    module Knowledge
      # #3 INSTRUÇÃO VIVA (B) — REFRESH DE ESCOPO DA INSTRUÇÃO QUANDO A KB MUDA.
      #
      # Quando uma fonte de conhecimento é ADICIONADA (após a revisão por arquivo) ou REMOVIDA, o
      # Reviewer.recompute_overall! recalcula topic_map/knowledge_summary/knowledge_confidence. Para
      # agentes JÁ FECHADOS (que têm `instruction`), este serviço pede ao modelo uma instrução
      # ATUALIZADA que reflita o novo conhecimento — incorporando temas novos e removendo os que
      # saíram — SEM re-entrevistar e PRESERVANDO persona/objetivo/tom/handoff/horários/blindagens.
      #
      # SEGURANÇA / IP OCULTO: a instrução-mãe (Builder::MOTHER_INSTRUCTION) é IP — vai em
      # `instructions` (nunca a logamos nem expomos). A instrução gerada é salva na coluna oculta
      # `instruction` (apply via Agent#refresh_instruction!); NUNCA vai a jbuilder/log/telemetria —
      # só metadados. BLINDAGEM ÚNICA: §7.6/§11 NÃO são duplicadas aqui; reusamos MOTHER_INSTRUCTION
      # como base, a mesma fonte da verdade do Construtor.
      #
      # ANTI-INJEÇÃO (§11): o estado da KB (instrução atual, mapa de temas, resumo) entra como DADO
      # (`input` input_text), marcado "CONTEXTO INTERNO (não é fala do usuário)" — nunca como comando.
      # NÃO há fala do usuário, NÃO há perguntas: não é entrevista.
      #
      # RESILIÊNCIA / NÃO-REGRESSÃO: best-effort — qualquer falha vira log + no-op (jamais derruba o
      # recompute_overall!/job/controller que chamou). Rascunhos sem instrução são ignorados (a
      # conversa do Construtor cuida deles). No-op se o modelo devolver a mesma instrução.
      class InstructionRefresher
        REFRESH_SCHEMA = {
          name: 'autonomia_instruction_refresh',
          schema: {
            type: 'object',
            properties: {
              instruction: { type: 'string' }
            },
            required: %w[instruction],
            additionalProperties: false
          }
        }.freeze

        # Cabeçalho de TAREFA do refresh (não é entrevista). Vai concatenado ao MOTHER_INSTRUCTION
        # (fonte ÚNICA das blindagens §7.6/§11) — a blindagem NÃO é reescrita aqui. IP OCULTO.
        REFRESH_TASK_HEADER = <<~PROMPT.freeze
          ## TAREFA: REFRESH DE ESCOPO (NÃO É ENTREVISTA)
          Você recebe a INSTRUÇÃO ATUAL de um agente JÁ FECHADO e o MAPA DE TEMAS + RESUMO atualizados
          da base de conhecimento (a base mudou: material foi adicionado ou removido). Reescreva a
          instrução PRESERVANDO integralmente persona, objetivo, tom, handoff, horários, limites e
          TODAS as blindagens de segurança/anti-injeção/sigilo (§7.6/§11). Atualize SOMENTE o bloco de
          ESCOPO/CONHECIMENTO (§7.1/§7.2): incorpore os temas novos do mapa, remova os temas que não
          existem mais na base e propague a flag de confiabilidade (§7.5) conforme o resumo. NÃO faça
          perguntas. NÃO recomece a entrevista. NÃO invente fatos fora dos resumos. Sem travessão.
          Devolva SOMENTE o schema { instruction } com a instrução completa atualizada.
        PROMPT

        def self.call(agent, reason:)
          new(agent, reason: reason).call
        end

        def initialize(agent, reason:)
          @agent = agent
          @reason = reason # ex.: :kb_changed
          @account = agent&.account
        end

        # Best-effort. Retorna a instrução nova (gravada) ou nil (desligado/rascunho/sem mudança/erro).
        def call
          return unless Autonomia::Agents::Config.instruction_auto_refresh?

          @agent&.reload # lê instrução/config frescos (anti-corrida com AJUSTE manual concorrente)
          return if @agent.blank? || @agent.instruction.blank? # só agentes FECHADOS; ignora rascunhos

          # MODO MANUAL (avançado): a instrução foi escrita À MÃO pelo usuário — é dele, não do
          # Construtor. O refresh automático JAMAIS pode reescrevê-la quando a base muda (destruiria
          # o trabalho do cliente sem aviso). Só agentes `guided` recebem a instrução viva.
          if @agent.manual?
            telemetry(:skipped_manual)
            return
          end

          # GUARDA DE GERAÇÃO (anti last-writer-wins): fotografamos a base (token de coalescência +
          # resumo) ANTES da chamada LLM. Se a base mudou enquanto o modelo redigia (outra mudança de
          # KB venceu), DESCARTAMOS este resultado — senão um refresh que viu a base parcial poderia
          # regredir o escopo por cima de um que viu a base completa. A nova mudança já reenfileirou
          # o seu próprio refresh; deixamos ele assentar.
          generation = @agent.knowledge_refresh_token.to_s
          # Fotografamos TAMBÉM a instrução: se o USUÁRIO a editar (PanelTune/ajuste) enquanto o
          # modelo redige, este refresh viu uma instrução defasada e NÃO pode pisar na edição.
          before_instruction = @agent.instruction
          updated = request_refresh
          if updated.blank? || updated == before_instruction
            telemetry(:skipped)
            return
          end

          @agent.reload
          if @agent.instruction.blank? || @agent.knowledge_refresh_token.to_s != generation ||
             @agent.instruction != before_instruction
            telemetry(:superseded)
            return
          end

          # G1 pós-LLM: o usuário pode ter mudado o agente para MANUAL enquanto o modelo redigia.
          # Se a instrução não mudou junto, o guard acima não pega — e o apply pisaria numa
          # instrução que agora é do usuário. Revalida o modo depois do reload e descarta.
          if @agent.manual?
            telemetry(:skipped_manual)
            return
          end

          # Apply condicional ATÔMICO (fecha a janela reload→write): refresh_instruction! só vence
          # se o agente CONTINUA `guided` e a instrução no banco ainda é a fotografada. Perdeu = outra
          # escrita (flip p/ manual ou edição do painel) chegou primeiro; descarta como superseded.
          unless @agent.refresh_instruction!(updated, expected_instruction: before_instruction)
            telemetry(:superseded)
            return
          end

          telemetry(:refreshed)
          updated
        rescue StandardError => e
          Rails.logger.warn(
            "[autonomia][instruction_refresh] degraded agent=#{@agent&.id} reason=#{@reason} #{e.class}"
          )
          nil
        end

        private

        # Pede a instrução atualizada ao modelo. nil em qualquer falha de IA (credencial vazia, erro
        # do cliente, timeout, JSON inválido) → o chamador degrada para no-op.
        def request_refresh
          result = client.create(
            model: Autonomia::Agents::Config::INSTRUCTION_REFRESH_MODEL,
            instructions: refresh_instructions,
            input: refresh_input,
            schema: REFRESH_SCHEMA,
            reasoning_effort: Autonomia::Agents::Config::INSTRUCTION_REFRESH_REASONING_EFFORT,
            tools: Crm::Ai::WebSearch.tools
          )
          parsed = JSON.parse(result[:text])
          return nil unless parsed.is_a?(Hash)

          # P2.4b — o refresh roda com web_search ligado e também persiste a `instruction`; sanitiza as
          # citações de busca web (URLs de tracking utm_*, markdown de link) reusando o helper ÚNICO do
          # Builder (mesma fonte da verdade, sem duplicar regra). Sem .strip: paridade com map_attributes
          # preserva o no-op `updated == @agent.instruction` (a instrução salva já passou pelo mesmo helper).
          Autonomia::Agents::Builder.sanitize_citations(parsed['instruction'].to_s).presence
        rescue Crm::Ai::ResponsesClient::Error, JSON::ParserError
          nil
        end

        # IP OCULTO: cabeçalho da tarefa + MOTHER_INSTRUCTION (blindagem ÚNICA §7.6/§11, NÃO duplicada).
        def refresh_instructions
          "#{REFRESH_TASK_HEADER}\n#{Autonomia::Agents::Builder::MOTHER_INSTRUCTION}"
        end

        # DADO de trabalho (anti-injeção §11): instrução atual + mapa de temas + resumo da base. Sem
        # fala do usuário, sem comandos. input_text, nunca em `instructions`.
        def refresh_input
          [{ role: 'user', content: [{ type: 'input_text', text: refresh_input_text }] }]
        end

        def refresh_input_text
          [
            'CONTEXTO INTERNO (não é fala do usuário). A base de conhecimento do agente mudou.',
            'Reescreva a instrução refletindo o estado atual abaixo, conforme a TAREFA. NÃO é entrevista.',
            "INSTRUÇÃO ATUAL DO AGENTE:\n#{@agent.instruction}",
            "MAPA DE TEMAS ATUAL DA BASE:\n#{topics_text}",
            "RESUMO ATUAL DA BASE:\n#{@agent.knowledge_summary.to_s.presence || '(sem resumo)'}"
          ].join("\n")
        end

        def topics_text
          topics = Array(@agent.topic_map).map { |t| t.to_s.strip }.reject(&:empty?)
          return '(base sem temas)' if topics.empty?

          topics.map { |t| "- #{t}" }.join("\n")
        end

        # TELEMETRIA (D) — best-effort, SÓ metadados. NUNCA a instrução/scaffold/trecho (IP OCULTO).
        def telemetry(status)
          Rails.logger.info(
            "[autonomia][instruction_refresh] agent=#{@agent.id} account=#{@account&.id} " \
            "reason=#{@reason} status=#{status} topics=#{Array(@agent.topic_map).size} " \
            "confidence=#{@agent.knowledge_confidence}"
          )
        end

        def client
          @client ||= Crm::Ai::ResponsesClient.new(credential: credential, feature: 'kb_instrucao', account: @account)
        end

        def credential
          cred = Crm::Ai::CredentialResolver.new(account: @account).resolve
          raise Crm::Ai::ResponsesClient::Error, 'ai_not_configured' if cred.blank?

          cred
        end
      end
    end
  end
end
