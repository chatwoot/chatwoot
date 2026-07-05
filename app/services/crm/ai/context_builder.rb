module Crm
  module Ai
    class ContextBuilder
      MAX_RECENT_MESSAGES = 12

      def initialize(card:)
        @card = card
      end

      def perform
        {
          summary: ai_metadata['summary'].to_s,
          recent_messages: recent_messages,
          current_stage: {
            id: @card.stage_id,
            name: @card.stage&.name
          },
          known_attributes: known_attributes,
          temporal: temporal_context
        }
      end

      private

      # Valores JÁ salvos dos atributos customizados (contato + conversa). O classificador recebe o
      # SCHEMA (chaves permitidas) em attribute_schema; aqui vão os VALORES atuais, para ele decidir o
      # estágio ciente do que já se sabe e não re-extrair o que não mudou.
      def known_attributes
        {
          contact: attribute_values(@card.try(:contact)),
          conversation: attribute_values(@card.primary_conversation)
        }
      end

      def attribute_values(record)
        attributes = record.try(:custom_attributes)
        return {} unless attributes.is_a?(Hash)

        # compact_blank descartaria `false` (false.blank? == true), mas checkbox salvo como
        # false é valor real. Removemos só nil/""/coleções vazias, preservando false e 0.
        attributes.reject { |_key, value| value != false && value.blank? }
      end

      # Âncora temporal para a IA resolver datas relativas ("amanhã", "terça que vem") em data real.
      # Fuso resolvido como nos follow-ups (contato → account.reporting_timezone → UTC).
      def temporal_context
        tz = Config.resolved_timezone(account: @card.account, contact: @card.try(:contact))
        now_local = Time.current.in_time_zone(tz)
        {
          timezone: tz,
          now_local: now_local.strftime('%Y-%m-%dT%H:%M'),
          weekday: now_local.strftime('%A'),
          default_hour: Config::CALLBACK_DEFAULT_HOUR
        }
      end

      def ai_metadata
        (@card.metadata || {}).fetch('ai', {}).to_h
      end

      def recent_messages
        conversation = @card.primary_conversation
        return [] if conversation.blank?

        # reorder (not order) to override Message's default_scope(created_at: :asc),
        # and by id (arrival order) so just-arrived messages/media are always in the
        # recent window even if provider timestamps are skewed/out-of-order.
        conversation.messages
                    .where(private: false)
                    .where.not(message_type: :activity)
                    .reorder(id: :desc)
                    .limit(MAX_RECENT_MESSAGES)
                    .reverse
                    .map { |message| format_message(message) }
      end

      def format_message(message)
        role = message.incoming? ? 'customer' : 'agent'
        {
          role: role,
          content: message_content(message).truncate(2000),
          created_at: message.created_at.iso8601
        }
      end

      # Combines the text body with text extracted from media attachments
      # (audio transcription, image caption) and presence markers for media we
      # don't process (video, document).
      def message_content(message)
        parts = []
        text = message.content.to_s.strip
        parts << text if text.present?
        message.attachments.each { |attachment| parts << media_fragment(attachment) }
        parts.compact_blank.join("\n").presence || '[mensagem sem texto]'
      end

      def media_fragment(attachment)
        meta = attachment.meta.to_h
        case attachment.file_type.to_s
        when 'audio'
          transcript = meta['transcribed_text'].to_s.strip
          transcript.present? ? "[áudio transcrito]: #{transcript.truncate(Config::TRANSCRIPT_MAX_CHARS)}" : '[áudio recebido, não transcrito]'
        when 'image'
          caption = meta['ai_caption'].to_s.strip
          caption.present? ? "[imagem]: #{caption.truncate(Config::CAPTION_MAX_CHARS)}" : '[imagem recebida]'
        when 'video'
          '[vídeo recebido]'
        when 'file'
          '[documento recebido]'
        end
      end
    end
  end
end
