module ChatwootGlpiIntegration
  # Creates a GLPI ticket from a Chatwoot conversation and/or Kanban card.
  # Returns the persisted TicketLink.
  class CreateTicketService
    def initialize(connection:, conversation: nil, kanban_card: nil, actor: nil, override: {})
      @connection    = connection
      @conversation  = conversation
      @kanban_card   = kanban_card
      @actor         = actor
      @override      = override
      raise ArgumentError, 'conversation or kanban_card required' if conversation.nil? && kanban_card.nil?
    end

    def call
      payload  = build_payload
      response = GlpiClient.new(@connection).create_ticket(payload)
      ticket_id = extract_ticket_id(response)

      TicketLink.create!(
        account_id:      @connection.account_id,
        conversation_id: @conversation&.id,
        kanban_card_id:  @kanban_card&.id,
        glpi_ticket_id:  ticket_id,
        sync_direction:  @override[:sync_direction] || 'both',
        last_synced_at:  Time.current
      )
    end

    private

    def build_payload
      {
        name:                 title,
        content:              body,
        entities_id:          @override[:entities_id]      || @connection.default_entity_id,
        itilcategories_id:    @override[:category_id]      || @connection.default_itil_category_id,
        type:                 @override[:request_type_id]  || @connection.default_request_type_id,
        urgency:              @override[:urgency]          || derive_urgency,
        impact:               @override[:impact]           || 3,
        priority:             @override[:priority]         || derive_urgency,
        status:               1   # 1 = New in GLPI
      }.compact
    end

    def title
      return @override[:title] if @override[:title].present?
      return "Chatwoot ##{@conversation.display_id} — #{contact_name}" if @conversation
      "Kanban card ##{@kanban_card.id} — #{@kanban_card.title}"
    end

    def body
      return @override[:content] if @override[:content].present?

      lines = []
      if @conversation
        lines << "Linked Chatwoot conversation: ##{@conversation.display_id}"
        lines << "Contact: #{contact_name} (#{@conversation.contact&.email || 'no email'})"
        first_msg = @conversation.messages.where(message_type: :incoming).order(:created_at).first
        lines << "\nOriginal message:\n#{first_msg.content}" if first_msg
      end
      if @kanban_card
        lines << "Linked Kanban card: ##{@kanban_card.id} — #{@kanban_card.title}"
        lines << @kanban_card.description if @kanban_card.description.present?
      end
      lines.join("\n")
    end

    def contact_name
      @conversation&.contact&.name.presence || 'unknown'
    end

    # GLPI urgency scale: 1 (very low) → 5 (very high)
    def derive_urgency
      source = @kanban_card&.priority.to_s.presence || @conversation&.priority.to_s
      case source
      when 'urgent' then 5
      when 'high'   then 4
      when 'medium' then 3
      when 'low'    then 2
      else               3
      end
    end

    def extract_ticket_id(response)
      # GLPI returns { "id": <int>, ... } on success, or an array of such objects.
      return response['id'] if response.is_a?(Hash) && response['id']
      return response.first['id'] if response.is_a?(Array) && response.first.is_a?(Hash)

      raise GlpiClient::RemoteError, "Could not extract ticket id from #{response.inspect}"
    end
  end
end
