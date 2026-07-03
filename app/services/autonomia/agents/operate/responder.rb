module Autonomia
  module Agents
    module Operate
      # Fase C "Operar" — RESPONDER (modelo INSTRUÇÃO-DIRIGIDO). Chamado pelo ReplyJob (após o debounce)
      # com a conversa elegível (SEM responsável + AgentInbox de agente ATIVO; status é irrelevante).
      # Monta o histórico das N últimas mensagens públicas, chama o Answerer em modo trust_instruction e:
      #   - se a resposta for o SINAL DE SILÊNCIO (`conversation_closed_for_now`) -> NÃO posta nada (fica
      #     em silêncio); é a instrução dizendo "não responda agora" (anti-loop / robôs / despedidas);
      #   - se a resposta vier vazia (falha de IA) -> SILÊNCIO (sem fallback de sistema);
      #   - caso contrário -> posta a resposta OUTGOING pelo caminho canônico (Messages::MessageBuilder
      #     com sender AgentBot espelho), igual ao Crm::FollowUps::MessageSender.
      #
      # SEM HANDOFF DE SISTEMA: "passar para humano" é só TEXTO da instrução. O handoff real é
      # operacional (humano assume a conversa, ou o CRM move de caixa). Não há bot_handoff! aqui.
      #
      # ANTI-LOOP: a mensagem postada é OUTGOING (sender AgentBot), logo NUNCA é incoming e o
      # MessageListener a ignora. SEGURANÇA/IP: só o texto destinado ao cliente é postado; nunca
      # instruction/scaffold/prompt vai à mensagem/log/content_attributes — só o id do agente.
      class Responder
        # Sinal de silêncio padrão (a instrução emite isto em vez de uma resposta). Override por agente
        # via config['silence_tokens'] (lista). Match exato após normalizar (trim + minúsculas + markdown).
        SILENCE_TOKEN = 'conversation_closed_for_now'.freeze

        Result = Struct.new(:status, :message, :error, keyword_init: true) do
          def self.replied(message)
            new(status: :replied, message: message)
          end

          # Não postou (sinal de silêncio, IA indisponível, ou não-elegível na hora de postar).
          def self.silenced
            new(status: :silenced)
          end
        end

        def initialize(conversation:, agent_inbox:, reply_to_message_id: nil)
          @conversation = conversation
          @agent_inbox  = agent_inbox
          @agent        = agent_inbox.agent
          @reply_to_message_id = reply_to_message_id
        end

        # -> Result
        def perform
          # C4 (custo): recheck BARATO de elegibilidade ANTES da chamada cara de IA (LLM + embedding).
          # Entre o debounce e este ponto um humano pode ter assumido a conversa (ou o agente foi
          # desligado/movido de caixa) — sem esta guarda o custo da geração já teria sido pago à toa.
          # O recheck autoritativo pós-IA (dentro do lock, em classic_deliver/deliver_*) PERMANECE.
          return Result.silenced unless still_eligible?

          # A chamada à IA (lenta) roda FORA do lock para não segurar a linha da conversa.
          result = answer
          # SINAL DE SILÊNCIO da instrução -> não posta nada (IF-node "parar"). Anti-loop / automações.
          return Result.silenced if silence_signal?(result)
          # Sem texto utilizável (falha de IA / resposta vazia) -> SILÊNCIO, sem fallback de sistema.
          return Result.silenced if result.nil? || result.reply.to_s.strip.blank?

          deliver(result)
        rescue StandardError => e
          # Falha inesperada ao postar -> SILÊNCIO (sem texto de sistema). Loga p/ diagnóstico.
          Rails.logger.warn("[autonomia][operate] responder_failed agent=#{@agent.id} conv=#{@conversation.id} #{e.class}")
          Result.silenced
        end

        # A resposta do agente é o sinal de silêncio? (compara o texto inteiro, normalizado, com o(s)
        # token(s) de silêncio). A instrução é quem decide emitir o sinal; aqui o sistema só HONRA.
        def silence_signal?(result)
          reply = result&.reply.to_s
          return false if reply.blank?

          silence_tokens.include?(normalize_token(reply))
        end

        def silence_tokens
          custom = Array(@agent.config&.dig('silence_tokens')).map { |token| normalize_token(token) }.reject(&:blank?)
          custom.presence || [normalize_token(SILENCE_TOKEN)]
        end

        # Normaliza p/ comparação: minúsculas + tira espaços e aspas/crase/asterisco SÓ das pontas
        # (markdown que o modelo às vezes adiciona). NUNCA mexe nos underscores internos do token.
        def normalize_token(value)
          value.to_s.strip.downcase.gsub(/\A["'`*\s]+|["'`*\s]+\z/, '')
        end

        private

        # Escolhe o caminho de entrega (extraído do perform p/ legibilidade; mesma ordem de sempre):
        #   1) ESPELHAMENTO DE ÁUDIO (Onda 2c, gated): cliente mandou áudio neste turno + recurso
        #      ligado -> responde EM ÁUDIO (TTS). Falha de síntese -> cai no texto (nunca fica mudo).
        #   2) ENTREGA HUMANIZADA (aditiva, kill-switch): quebra em pedaços com "digitando" + pausa.
        #   3) OFF (ENV/por-agente) -> caminho CLÁSSICO de 1 mensagem (ZERO mudança de comportamento).
        def deliver(result)
          return deliver_voice(result) if voice_reply_applies?
          return deliver_humanized(result) if ::Autonomia::Agents::Config.humanize_delivery_enabled?(@agent)

          classic_deliver(result)
        end

        # Caminho CLÁSSICO: 1 mensagem única (comportamento original, intocado). Usado quando a
        # humanização está OFF e como FALLBACK quando o quebrador não produz pedaço (resposta só com
        # caracteres invisíveis) — preserva paridade exata com o modo OFF.
        #
        # Lock por conversa só na hora de postar: reavalia elegibilidade com estado fresco (um humano
        # pode ter assumido durante a chamada à IA) e garante idempotência (retry do Sidekiq após post
        # não duplica). IMPORTANTE (Rails 7.1): NÃO usar return/break dentro do with_lock — dispararia
        # ROLLBACK e descartaria a mensagem recém-postada. Computa-se o Result numa variável.
        def classic_deliver(result)
          outcome = @conversation.with_lock do
            if !still_eligible?
              Result.silenced
            elsif already_replied?
              Result.replied(nil)
            else
              Result.replied(post_reply!(result.reply))
            end
          end

          # Fase F (ADITIVO/best-effort): só registra quando uma resposta NOVA foi postada
          # (outcome.message presente — exclui already_replied?, que devolve message nil, e
          # o caso still_eligible?==false, que virou handoff). EventLogger nunca levanta.
          if outcome.status == :replied && outcome.message.present?
            ::Autonomia::Agents::Operate::EventLogger.replied(
              agent: @agent, conversation: @conversation, result: result
            )
          end
          outcome
        end

        # ESPELHAMENTO DE ÁUDIO: só quando o cliente mandou áudio NESTE turno (media.transcripts) e o
        # recurso está ligado (ENV/por-agente). Caso contrário, fluxo de texto normal.
        def voice_reply_applies?
          media.transcripts.any? && ::Autonomia::Agents::Config.voice_reply_enabled?(@agent)
        end

        # Sintetiza a resposta em áudio (TTS) e posta como mensagem outgoing SÓ-ÁUDIO. A síntese (lenta)
        # roda FORA do lock; o lock só posta. Falha/áudio vazio -> cai no texto (post_reply!), nunca mudo.
        def deliver_voice(result)
          audio = synthesize_audio(result.reply) # fora do lock; nil em falha
          outcome = @conversation.with_lock do
            if !still_eligible?
              Result.silenced
            elsif already_replied?
              Result.replied(nil)
            elsif audio.present?
              Result.replied(post_audio_reply!(audio))
            else
              Result.replied(post_reply!(result.reply)) # fallback texto
            end
          end
          if outcome.status == :replied && outcome.message.present?
            ::Autonomia::Agents::Operate::EventLogger.replied(agent: @agent, conversation: @conversation, result: result)
          end
          outcome
        end

        # -> bytes (opus) ou nil. NUNCA loga o texto. Fail-safe (qualquer erro -> nil -> fallback texto).
        def synthesize_audio(text)
          credential = Crm::Ai::CredentialResolver.new(account: @agent.account).resolve
          return if credential.blank?

          Crm::Ai::SpeechClient.new(credential: credential)
                               .synthesize(text,
                                           voice: ::Autonomia::Agents::Config.voice_for(@agent),
                                           instructions: ::Autonomia::Agents::Config.voice_instructions_for(@agent))
        rescue StandardError => e
          Rails.logger.warn("[autonomia][operate] tts_failed agent=#{@agent.id} #{e.class}")
          nil
        end

        # Mensagem outgoing SÓ-ÁUDIO (espelhamento): mesmo sender/anti-loop do post_reply!, com o anexo de
        # áudio construído ANTES do save (o envio por canal dispara nos callbacks da Message outgoing).
        def post_audio_reply!(audio_bytes)
          message = @conversation.messages.new(
            content: '',
            account_id: @agent_inbox.account_id,
            inbox_id: @conversation.inbox_id,
            message_type: :outgoing,
            sender_type: 'AgentBot',
            sender_id: @agent_inbox.agent_bot_id,
            content_attributes: {
              autonomia_agent_id: @agent.id,
              autonomia_reply_to_message_id: @reply_to_message_id,
              autonomia_voice: true
            }
          )
          # meta['is_voice_message']=true -> os provedores (WhatsApp Cloud etc.) enviam como ÁUDIO DE VOZ
          # (voice note), não como arquivo de áudio comum — mesmo contrato do caminho canônico do core.
          message.attachments.new(account_id: @agent_inbox.account_id, file_type: :audio,
                                  meta: { 'is_voice_message' => true }).tap do |att|
            att.file.attach(io: StringIO.new(audio_bytes), filename: 'resposta.ogg', content_type: 'audio/ogg')
          end
          message.save!
          message
        end

        # Inicia a entrega humanizada: quebra a resposta, mostra "digitando" e agenda o 1º pedaço.
        # Guardas baratas aqui (idempotência/elegibilidade); as AUTORITATIVAS (lock + token + por-chunk)
        # vivem no ChunkedDeliveryJob. NÃO posta nada de forma síncrona.
        def deliver_humanized(result)
          return Result.replied(nil) if already_replied?      # um settle anterior já entregou
          return Result.silenced unless still_eligible?       # humano assumiu durante a IA -> não posta

          chunks = ::Autonomia::Agents::Operate::ReplyChunker.call(result.reply)
          # Nada a quebrar (ex.: resposta só com invisíveis) -> caminho clássico (paridade com OFF),
          # nunca engole a resposta silenciosamente.
          return classic_deliver(result) if chunks.empty?

          meta = { 'confidence' => result.confidence, 'answered_from_knowledge' => result.answered_from_knowledge }
          ::Autonomia::Agents::Operate::TypingIndicator.new(conversation: @conversation, agent_inbox: @agent_inbox).on
          ::Autonomia::Agents::Operate::ChunkedDeliveryJob
            .set(wait: (chunks.first['delay_ms'].to_i / 1000.0).clamp(0.1, 30.0).seconds)
            .perform_later(@conversation.id, @agent_inbox.id, @reply_to_message_id, chunks, 0, meta)
          Result.replied(nil)
        end

        # Motor de resposta em modo INSTRUÇÃO-DIRIGIDO: devolve a resposta do modelo como veio (sem
        # portão de confiança nem handoff de sistema). reply pode vir nil (falha de IA) -> silêncio.
        # MULTIMODAL (Onda 2 / Track B): passa as imagens/figurinhas do turno como input_image; a
        # transcrição de áudio já vem embutida em `query`.
        def answer
          ::Autonomia::Agents::Answerer.new(
            agent: @agent,
            query: query,
            history: history,
            images: media.images,
            trust_instruction: true
          ).answer
        end

        # Mídia do turno atual (imagens/figurinhas inline + transcrições de áudio), gateada por flag
        # global/por-agente. OFF -> vazio (responde só ao texto, ZERO regressão). Memoizada: uma vez por
        # perform (roda FORA do lock, junto da chamada lenta de IA).
        def media
          @media ||= if ::Autonomia::Agents::Config.operate_media_enabled?(@agent)
                       MessageMedia.new(messages: current_turn_incoming, agent: @agent).extract
                     else
                       MessageMedia::EMPTY
                     end
        end

        # Reavaliação FRESCA do CONTRATO INTEIRO (Operate.eligible_agent_inbox) dentro do lock, ainda
        # na MESMA caixa do agente: sem responsável + agente ligado/ativo/não-interno/não-sistema +
        # feature on + allowlist. Cobre o que mudou durante a chamada de IA (humano assumiu, agente
        # desligado, conversa movida de caixa) — em qualquer um desses casos NÃO posta.
        def still_eligible?
          fresh = ::Autonomia::Agents::Operate.eligible_agent_inbox(@conversation.reload)
          fresh.present? && fresh.id == @agent_inbox.id
        end

        # Idempotência: já existe uma resposta outgoing do bot para ESTA mensagem incoming?
        # Bloqueia post duplicado num retry do Sidekiq que ocorra após um post bem-sucedido.
        def already_replied?
          return false if @reply_to_message_id.blank?

          # `content_attributes` é coluna `json` gravada via Rails `store(coder: JSON)`,
          # i.e. STRING JSON dentro de json: `->>` devolve NULL e nunca casa, e no `::text`
          # as aspas internas vêm ESCAPADAS (`\"autonomia_reply_to_message_id\":123`). O id
          # serializa como NÚMERO (Integer do arg do Sidekiq) — `...:123` sem aspas — mas o
          # regex tolera também a forma string (`"?...?"`). Fronteira `[,}]` evita casar 12 em
          # 123. Sem isto a guarda anti-duplicata ficaria sempre falsa (retry -> resposta dupla).
          id = Regexp.escape(@reply_to_message_id.to_s)
          pattern = %(autonomia_reply_to_message_id\\\\?":"?#{id}"?[,}])
          @conversation.messages.outgoing.where(sender_type: 'AgentBot')
                       .where('content_attributes::text ~ ?', pattern)
                       .exists?
        end

        # query = última mensagem INCOMING pública (o que o contato acaba de perguntar), enriquecida com:
        # (1) o CONTEXTO da mensagem referenciada (reply citado / reação que chega como texto com
        # in_reply_to, ex.: WAHA "*Reagiu com* 👍") — dá ao modelo O QUE o cliente respondeu/reagiu;
        # (2) as transcrições de áudio do turno (uma mensagem de áudio costuma vir com content vazio).
        # Imagens NÃO entram aqui — vão como input_image.
        def query
          message = last_incoming_message
          base = message&.content.to_s
          transcribed = media.transcripts.map { |text| "[áudio do cliente, transcrito automaticamente]: #{text}" }
          [quoted_context(message), base.presence, *transcribed].compact.join("\n")
        end

        def last_incoming_message
          recent_messages.reverse.find(&:incoming?)
        end

        # Contexto da mensagem referenciada via `in_reply_to` (reply citado OU reação entregue como texto
        # pelo canal, ex.: WAHA). Escopado à conversa, truncado, fail-safe. Sem referência -> nil (a query
        # fica idêntica ao comportamento anterior).
        def quoted_context(message)
          ref_id = message&.content_attributes.to_h['in_reply_to']
          return if ref_id.blank?

          # `.chat` exclui notas PRIVADAS e activities (mesmo escopo do history) -> nunca vaza conteúdo
          # de nota interna ao LLM mesmo que in_reply_to aponte para uma (P1 privacidade, codex).
          referenced = @conversation.messages.chat.find_by(id: ref_id)
          quoted = referenced&.content.to_s.strip.tr("\n", ' ').first(160)
          return if quoted.blank?

          side = referenced.outgoing? ? 'sua mensagem' : 'uma mensagem anterior dele'
          "[Em referência a #{side}: \"#{quoted}\"]"
        rescue StandardError
          nil
        end

        # Incoming do TURNO atual = mensagens incoming após a última saída (bot/humano) na janela
        # recente; se não houve saída ainda, todas as incoming da janela. É daí que a mídia é extraída
        # (cobre o caso "cliente manda a imagem e o texto em mensagens separadas" dentro do debounce).
        def current_turn_incoming
          msgs = recent_messages
          last_outgoing_index = msgs.rindex { |message| !message.incoming? }
          window = last_outgoing_index ? msgs[(last_outgoing_index + 1)..] : msgs
          Array(window).select(&:incoming?)
        end

        # history = N últimas mensagens públicas (≤ HISTORY_MAX_TURNS pares), em ordem
        # cronológica, mapeadas para o formato do Answerer: incoming -> user,
        # outgoing -> assistant. Activity/private já são excluídas pelo scope `chat`.
        def history
          recent_messages.map do |message|
            { role: message.incoming? ? 'user' : 'assistant', content: message.content.to_s }
          end
        end

        # Mensagens públicas, não-activity, mais recentes -> mais antigas no banco;
        # devolvidas em ordem cronológica (ascendente). Limite generoso (pares*2).
        def recent_messages
          @recent_messages ||= @conversation.messages
                                            .chat
                                            .reorder(created_at: :desc)
                                            .limit(::Autonomia::Agents::Config::HISTORY_MAX_TURNS * 2)
                                            .to_a
                                            .reverse
        end

        # Caminho CANÔNICO channel-agnóstico (= Crm::FollowUps::MessageSender): a entrega
        # por canal (WhatsApp/Instagram/email/webchat) é feita pelos jobs de canal do
        # Chatwoot disparados nos callbacks da Message outgoing. Nada por-canal aqui.
        def post_reply!(text)
          Messages::MessageBuilder.new(
            nil,
            @conversation,
            ActionController::Parameters.new(
              content: text,
              message_type: 'outgoing',
              sender_type: 'AgentBot',
              sender_id: @agent_inbox.agent_bot_id, # AgentBot nativo-espelho
              private: false,
              content_attributes: {
                autonomia_agent_id: @agent.id,
                autonomia_reply_to_message_id: @reply_to_message_id
              }
            )
          ).perform
        end
      end
    end
  end
end
