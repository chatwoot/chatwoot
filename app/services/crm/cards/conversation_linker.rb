module Crm
  module Cards
    class ConversationLinker
      def initialize(card:, conversation:, actor:, primary: false)
        @card = card
        @conversation = conversation
        @actor = actor
        @primary = primary || card.conversation_id.blank?
      end

      def link
        ActiveRecord::Base.transaction do
          link = Crm::CardConversation.find_or_create_by!(
            account: @card.account,
            card: @card,
            conversation: @conversation
          ) do |record|
            record.linked_by = @actor
          end

          update_card_from_conversation! if @primary
          link.update!(is_primary: true) if @primary && !link.is_primary?
          log_activity('conversation_linked')
          @card.reload
        end
      end

      def unlink
        ActiveRecord::Base.transaction do
          Crm::CardConversation.where(card: @card, conversation: @conversation).destroy_all
          if @card.conversation_id == @conversation.id
            @card.update!(conversation_id: nil, last_activity_at: Time.current)
          else
            @card.update!(last_activity_at: Time.current)
          end
          log_activity('conversation_unlinked')
          @card.reload
        end
      end

      private

      def update_card_from_conversation!
        @card.update!(
          conversation_id: @conversation.id,
          contact_id: @card.contact_id || @conversation.contact_id,
          inbox_id: @card.inbox_id || @conversation.inbox_id,
          owner_id: @card.owner_id || @conversation.assignee_id,
          team_id: @card.team_id || @conversation.team_id,
          source: @card.source.presence || @conversation.inbox&.channel_type,
          last_message_at: Crm::Conversations::LastRealMessageAt.for(@conversation),
          last_activity_at: Time.current
        )
      end

      def log_activity(event_type)
        Crm::ActivityLogger.new(
          card: @card,
          actor: @actor,
          event_type: event_type,
          conversation: @conversation,
          payload: { conversation_id: @conversation.id }
        ).perform
      end
    end
  end
end
