module Crm
  module Cards
    class Creator
      ATTRIBUTES = %i[
        pipeline_id stage_id contact_id conversation_id inbox_id owner_id team_id title description
        value_cents currency status lost_reason source priority score expected_close_at metadata external_id
      ].freeze

      def initialize(account:, user:, params:, conversation: nil)
        @account = account
        @user = user
        @params = params.to_h.with_indifferent_access
        @conversation = conversation
      end

      def perform
        ActiveRecord::Base.transaction do
          card = @account.crm_cards.new(card_attributes)
          hydrate_from_conversation(card) if @conversation.present?
          card.owner ||= default_owner(card)
          card.save!
          link_primary_conversation(card) if card.conversation_id.present?
          Crm::ActivityLogger.new(card: card, actor: @user, event_type: 'create', payload: activity_payload(card)).perform
          card
        end
      end

      private

      def card_attributes
        @params.slice(*ATTRIBUTES).compact_blank
      end

      def hydrate_from_conversation(card)
        card.primary_conversation = @conversation
        card.contact = @conversation.contact
        card.inbox = @conversation.inbox
        card.owner = @conversation.assignee
        card.team = @conversation.team
        card.source = @conversation.inbox&.channel_type
        card.title = derived_title if card.title.blank?
        card.last_message_at ||= Crm::Conversations::LastRealMessageAt.for(@conversation)
        card.last_activity_at ||= @conversation.last_activity_at
        card.metadata = conversation_metadata(card)
      end

      def derived_title
        @params[:title].presence ||
          @conversation.contact&.name.presence ||
          @conversation.contact&.phone_number.presence ||
          "Conversa ##{@conversation.display_id}"
      end

      def conversation_metadata(card)
        (card.metadata || {}).merge(
          'source_conversation' => {
            'display_id' => @conversation.display_id,
            'status' => @conversation.status,
            'inbox_id' => @conversation.inbox_id,
            'assignee_id' => @conversation.assignee_id,
            'team_id' => @conversation.team_id
          }
        )
      end

      def default_owner(card)
        return nil if @user.blank?
        return @user if card.owner_id.blank?

        card.owner
      end

      def link_primary_conversation(card)
        Crm::CardConversation.find_or_create_by!(
          account: @account,
          card: card,
          conversation_id: card.conversation_id
        ) do |link|
          link.is_primary = true
          link.linked_by = @user
        end
      end

      def activity_payload(card)
        {
          pipeline_id: card.pipeline_id,
          stage_id: card.stage_id,
          contact_id: card.contact_id,
          conversation_id: card.conversation_id,
          inbox_id: card.inbox_id,
          owner_id: card.owner_id
        }.compact
      end
    end
  end
end
