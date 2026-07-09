module Crm
  module FollowUps
    # ENTREGA DO RETORNO POR DATA (callback, automation_mode auto_send_message, source ai_callback).
    # Chamado pelo DueProcessor no vencimento. Espelha o AutoFollowupRunner, mas é ONE-SHOT (sem
    # cadência/budget/retry-de-toque) e com enquadramento de CALLBACK no composer.
    #
    # DECISÃO DE PRODUTO: NÃO discrimina humano×IA — se o funil configurou "mensagem", a automação
    # dispara independente de quem está atendendo. As únicas guardas são de SITUAÇÃO (composer:
    # encerramento/desistência → não envia, vira lembrete pro humano).
    #
    # Entrega por canal (decidido pelo MessagingWindow, que já trata WAHA como livre-sempre):
    #   - free_form  → a IA GERA a mensagem (WAHA sempre; WhatsApp oficial dentro da janela).
    #   - template   → a IA ESCOLHE o melhor template aprovado (TemplateCandidates); se nenhum servir
    #                  (index -1) ou a IA não quiser enviar → FALLBACK: lembrete na tela (popup).
    class CallbackRunner
      Result = Struct.new(:status, :error, :retry_at, keyword_init: true) do
        def self.sent
          new(status: :sent)
        end

        def self.fallback(reason)
          new(status: :fallback, error: reason)
        end

        def self.failed(error, retry_at)
          new(status: :failed, error: error, retry_at: retry_at)
        end
      end

      RETRY_BACKOFF = 45.minutes
      # Após N falhas consecutivas (credencial quebrada / compose falhando), PARA de retransmitir
      # (cada tentativa é uma chamada de IA = custo) e cai para lembrete na tela. Espelha o budget do auto-followup.
      MAX_RETRIES = 3

      def initialize(follow_up:, now: Time.current)
        @follow_up = follow_up
        @now = now
        @card = follow_up.card
      end

      # -> Result (:sent | :fallback | :failed)
      def perform
        return Result.fallback('card_archived') if @card&.archived?
        return Result.fallback('no_conversation') if @follow_up.conversation.blank?

        @send_mode = messaging_window.can_send_session_message? ? :free_form : :choose_template
        @candidates = @send_mode == :choose_template ? template_candidates : []
        composition = compose

        return Result.fallback('closure') if closure?(composition)
        return Result.fallback(skip_reason) unless composable?(composition)

        prepare_send_metadata(composition)
        send_result = Crm::FollowUps::MessageSender.new(follow_up: @follow_up).perform
        case send_result.status
        when :sent, :skipped then Result.sent
        else fail_or_fallback(send_result.error)
        end
      rescue Crm::Ai::ResponsesClient::Error, JSON::ParserError => e
        # Falha de composição é transitória → retry limitado; estourado o budget vira lembrete.
        fail_or_fallback(e.message)
      end

      private

      # Retry com TETO: abaixo de MAX_RETRIES reagenda (DueProcessor mantém pending + bump due_at);
      # no teto desiste do envio e devolve :fallback (vira lembrete pro humano) — nunca retransmite IA infinito.
      def fail_or_fallback(error)
        meta = base_metadata
        attempts = meta['callback_retries'].to_i + 1
        meta['callback_retries'] = attempts
        @follow_up.update!(metadata: meta)
        return Result.fallback("send_failed_#{attempts}") if attempts >= MAX_RETRIES

        Result.failed(error, @now + RETRY_BACKOFF)
      end

      def compose
        client = Crm::Ai::ResponsesClient.new(
          credential: resolved_credential,
          feature: 'follow_up', account: @card.account, pipeline: @card.pipeline
        )
        context = Crm::Ai::ContextBuilder.new(card: @card).perform

        Crm::Ai::FollowUpComposer.new(
          card: @card,
          client: client,
          context: context,
          mode: @send_mode,
          candidates: @candidates,
          purpose: :callback,
          callback_context: {
            'requested_at_text' => base_metadata['requested_at_text'],
            'requested_at' => @follow_up.due_at&.iso8601
          },
          reasoning_effort: Crm::Ai::Config::CALLBACK_REASONING_EFFORT
        ).perform
      end

      # Fail closed: sem credencial vira transitório rescued (fail_or_fallback) e não
      # NoMethodError cru dentro do ResponsesClient (@credential[:api_key]).
      def resolved_credential
        credential = Crm::Ai::CredentialResolver.new(account: @card.account).resolve
        raise Crm::Ai::ResponsesClient::Error, 'missing_ai_credential' if credential.blank?

        credential
      end

      def closure?(composition)
        return false unless composition

        Crm::Ai::Config::BOOLEAN.cast(composition['closure_detected'])
      end

      def composable?(composition)
        return false unless composition
        return false unless Crm::Ai::Config::BOOLEAN.cast(composition['should_send'])
        return false if composition['confidence'].to_f < Crm::Ai::Config::FOLLOWUP_MIN_CONFIDENCE
        return resolved_candidate(composition).present? if @send_mode == :choose_template

        true
      end

      def skip_reason
        @send_mode == :choose_template ? 'no_template' : 'not_composable'
      end

      # Escreve follow_up.metadata para o MessageSender pegar o ramo certo (idêntico ao AutoFollowupRunner).
      def prepare_send_metadata(composition)
        metadata = base_metadata
        if @send_mode == :free_form
          metadata['message_body'] = composition['message_body'].to_s.strip
          %w[whatsapp_api_message_template_id template_name template_language template_processed_params].each { |k| metadata.delete(k) }
        else
          apply_template_metadata(metadata, composition)
        end
        @follow_up.update!(metadata: metadata)
      end

      def apply_template_metadata(metadata, composition)
        candidate = resolved_candidate(composition)
        metadata['message_body'] = composition['message_body'].to_s.strip.presence || metadata['message_body']

        if candidate[:kind].to_s == 'api'
          metadata['whatsapp_api_message_template_id'] = candidate[:id]
          %w[template_name template_language template_processed_params].each { |k| metadata.delete(k) }
        else
          metadata['template_name'] = candidate[:name].to_s
          metadata['template_language'] = candidate[:language].presence || 'pt_BR'
          metadata['template_processed_params'] = composition['template_variables'].to_h.transform_values(&:to_s)
          metadata.delete('whatsapp_api_message_template_id')
        end
      end

      def resolved_candidate(composition)
        return @resolved_candidate if defined?(@resolved_candidate)

        index = composition.dig('chosen_template', 'index')
        @resolved_candidate = (@candidates[index] if index.is_a?(Integer) && index >= 0)
      end

      def template_candidates
        Crm::FollowUps::TemplateCandidates.new(conversation: @follow_up.conversation).perform
      end

      def messaging_window
        @messaging_window ||= Crm::FollowUps::MessagingWindow.new(@follow_up.conversation, at: @now)
      end

      def base_metadata
        (@follow_up.metadata || {}).to_h.stringify_keys
      end
    end
  end
end
