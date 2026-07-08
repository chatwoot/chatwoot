module Crm
  module FollowUps
    # DETECÇÃO DE RETORNO POR DATA — cria/atualiza um LEMBRETE quando a IA (StageClassifier) detectou um
    # pedido de retorno com data concreta ("me liga terça que vem"). Chamado pelo Evaluator depois da
    # classificação. Aditivo e BEST-EFFORT: qualquer falha vira log e NÃO derruba a avaliação do card.
    #
    # v1 = só LEMBRETE (Crm::FollowUp reminder_only, type=call): risco mínimo, o humano confirma/liga.
    # O follow-up com due_at já aparece no calendário e no popup de lembrete (zero código extra lá).
    # Guardas contra falso-positivo: confiança mínima, data CONCRETA, futura e dentro do horizonte.
    # DEDUP/UPSERT: um card só tem UM lembrete de retorno da IA pendente — se o cliente remarcar, a data
    # mais recente vence (atualiza em vez de duplicar).
    class CallbackScheduler
      SOURCE = 'ai_callback'.freeze
      # Placeholder do body exigido na criação do auto_send_message (AutoSendValidator). O texto REAL
      # é gerado pela IA no envio (CallbackRunner), como no auto-followup.
      MESSAGE_PLACEHOLDER = 'Retomando nosso contato como combinado.'.freeze
      Config = Crm::Ai::Config

      def initialize(card:, callback:)
        @card = card
        @callback = callback.respond_to?(:with_indifferent_access) ? callback.with_indifferent_access : nil
      end

      # -> Crm::FollowUp | nil
      def perform
        return unless Config.callback_detection_enabled?
        return unless eligible?

        due_at = resolve_due_at
        return if due_at.nil?

        dispatch!(due_at)
      rescue StandardError => e
        Rails.logger.warn("[crm][callback] skipped card=#{@card&.id} #{e.class}: #{e.message.to_s[0,120]}")
        nil
      end

      private

      def eligible?
        @callback.present? &&
          ActiveModel::Type::Boolean.new.cast(@callback[:detected]) &&
          @callback[:confidence].to_f >= Config::CALLBACK_MIN_CONFIDENCE &&
          @callback[:requested_at].present?
      end

      # "YYYY-MM-DDTHH:MM" (hora LOCAL) -> Time UTC, validando fuso, futuro e horizonte.
      def resolve_due_at
        return if timezone.blank?

        zone = ActiveSupport::TimeZone[timezone]
        local = zone.parse(@callback[:requested_at].to_s)
        return if local.blank?

        utc = local.utc
        return unless utc > Time.current
        return if utc > Config::CALLBACK_MAX_HORIZON_DAYS.days.from_now

        utc
      rescue ArgumentError
        nil
      end

      # Cria os follow-ups conforme o MODO do funil. 'message'/'both' só viram auto_send_message se a
      # conversa for WhatsApp-capaz (senão degradam para lembrete — nunca trava). 'both' cria os dois.
      def dispatch!(due_at)
        case mode
        when 'message'
          wants_message? ? upsert(:auto_send_message, due_at) : upsert(:reminder_only, due_at)
        when 'both'
          reminder = upsert(:reminder_only, due_at)
          wants_message? ? upsert(:auto_send_message, due_at) : reminder
        else # 'reminder'
          upsert(:reminder_only, due_at)
        end
      end

      def mode
        @mode ||= Config.pipeline_callback_mode(@card.pipeline)
      end

      # Auto-envio só faz sentido com conversa WhatsApp-capaz (oficial OU WAHA).
      def wants_message?
        conversation.present? && Crm::FollowUps::MessagingWindow.new(conversation).whatsapp_capable?
      end

      # DEDUP por (card, source, automation_mode): 1 lembrete pendente + 1 mensagem pendente no máximo;
      # remarcar (nova data) atualiza o registro existente do MESMO tipo.
      def upsert(automation_mode, due_at)
        attrs = base_attrs(due_at).merge(automation_mode: automation_mode)
        if automation_mode == :auto_send_message
          attrs[:metadata] = attrs[:metadata].merge('message_body' => MESSAGE_PLACEHOLDER, 'callback_mode' => mode)
        end

        if (existing = existing_pending_callback(automation_mode))
          existing.update!(attrs)
          existing
        else
          @card.account.crm_follow_ups.create!(attrs.merge(card: @card))
        end
      end

      def base_attrs(due_at)
        {
          title: title,
          due_at: due_at,
          timezone: timezone,
          follow_up_type: :call,
          conversation: conversation,
          contact: contact,
          inbox: conversation&.inbox,
          assignee_id: @card.try(:owner_id),
          metadata: metadata
        }
      end

      def existing_pending_callback(automation_mode)
        Crm::FollowUp
          .where(account_id: @card.account_id, card_id: @card.id, status: Crm::FollowUp.statuses[:pending],
                 automation_mode: Crm::FollowUp.automation_modes[automation_mode])
          .where("metadata ->> 'source' = ?", SOURCE)
          .order(created_at: :desc)
          .first
      end

      def title
        text = @callback[:requested_at_text].to_s.strip
        base = 'Retorno solicitado pelo cliente'
        text.present? ? "#{base}: #{text}".truncate(120) : base
      end

      def metadata
        {
          'source' => SOURCE,
          'requested_at_text' => @callback[:requested_at_text].to_s,
          'confidence' => @callback[:confidence].to_f
        }
      end

      def timezone
        @timezone ||= Crm::Timezone::Resolver.new(contact: contact, account: @card.account).name
      end

      def contact
        @contact ||= @card.try(:contact)
      end

      def conversation
        @conversation ||= @card.try(:primary_conversation)
      end
    end
  end
end
