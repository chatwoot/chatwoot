# frozen_string_literal: true

module LeadRetargeting
  class EligibleConversationsQueryBuilder
    ALLOWED_DATE_COLUMNS = {
      'conversation_created_at' => 'conversations.created_at',
      'inactive_days' => 'conversations.last_chat_message_at'
    }.freeze

    def self.call(account_id:, inbox_id:, trigger_conditions: {}, include_cancelled: true, include_completed: true, stop_on_contact_reply: false, sequence_id: nil)
      new(
        account_id: account_id,
        inbox_id: inbox_id,
        trigger_conditions: trigger_conditions,
        include_cancelled: include_cancelled,
        include_completed: include_completed,
        stop_on_contact_reply: stop_on_contact_reply,
        sequence_id: sequence_id
      ).build
    end

    def initialize(account_id:, inbox_id:, trigger_conditions:, include_cancelled:, include_completed:, stop_on_contact_reply:, sequence_id:)
      @account_id = account_id
      @inbox_id = inbox_id
      @trigger_conditions = trigger_conditions || {}
      @include_cancelled = include_cancelled
      @include_completed = include_completed
      @stop_on_contact_reply = stop_on_contact_reply
      @sequence_id = sequence_id
    end

    def build
      query = base_query
      query = apply_enrollment_filter(query)
      query = apply_date_filter(query)
      query = apply_status_filter(query)
      query = apply_pipeline_status_filter(query)
      query = apply_label_filter(query)
      query
    end

    private

    attr_reader :account_id, :inbox_id, :trigger_conditions, :include_cancelled, :include_completed, :stop_on_contact_reply, :sequence_id

    def base_query
      Conversation.where(account_id: account_id, inbox_id: inbox_id)
    end

    def apply_enrollment_filter(query)
      query = query.left_joins(:conversation_follow_up)

      # Construir array de estados permitidos basado en parámetros
      allowed_statuses = []
      allowed_statuses << 'cancelled' if include_cancelled
      allowed_statuses << 'completed' if include_completed
      allowed_statuses << 'failed' if include_completed # failed también cuenta como terminado

      if sequence_id.present?
        # Para vista de edición/show: permitir conversaciones sin follow-up O con follow-ups en estados permitidos de ESTA secuencia
        if allowed_statuses.any?
          query.where(
            'conversation_follow_ups.id IS NULL OR ' \
            '(conversation_follow_ups.lead_follow_up_sequence_id = ? AND conversation_follow_ups.status IN (?))',
            sequence_id,
            allowed_statuses
          )
        else
          query.where(conversation_follow_up: { id: nil })
        end
      else
        # Para enrollment automático: permitir conversaciones sin follow-up O con follow-ups en estados permitidos
        if allowed_statuses.any?
          query.where('conversation_follow_ups.id IS NULL OR conversation_follow_ups.status IN (?)', allowed_statuses)
        else
          query.where(conversation_follow_up: { id: nil })
        end
      end
    end

    def apply_status_filter(query)
      filter = trigger_conditions.dig('status_filter')
      if filter&.dig('enabled') && filter['statuses'].present?
        query.where('conversations.status' => filter['statuses'])
      else
        query
      end
    end

    def apply_pipeline_status_filter(query)
      filter = trigger_conditions.dig('pipeline_status_filter')

      if filter&.dig('enabled') && filter['pipeline_status_ids'].present?
        query.where('conversations.pipeline_status_id' => filter['pipeline_status_ids'])
      else
        query
      end
    end

    def apply_date_filter(query)
      filter = trigger_conditions.dig('date_filter')

      if filter&.dig('enabled')
        filter_type = filter['filter_type']

        if filter_type == 'last_message_at'
          apply_date_operator(query, 'conversations.last_chat_message_at', filter)
        elsif ALLOWED_DATE_COLUMNS.key?(filter_type)
          column = ALLOWED_DATE_COLUMNS[filter_type]
          apply_date_operator(query, column, filter)
        else
          Rails.logger.warn "Unknown date filter type: #{filter_type}"
          query
        end
      else
        query.where('conversations.created_at > ?', 30.days.ago)
      end
    end

    def apply_date_operator(query, column, filter)
      case filter['operator']
      when 'older_than'
        query.where("#{column} < ?", filter['value'].to_i.days.ago)
      when 'newer_than'
        query.where("#{column} > ?", filter['value'].to_i.days.ago)
      when 'between'
        from_date = Date.parse(filter['from_date']).beginning_of_day
        to_date = Date.parse(filter['to_date']).end_of_day
        query.where("#{column} BETWEEN ? AND ?", from_date, to_date)
      else
        query
      end
    rescue ArgumentError => e
      Rails.logger.error "Invalid date in filter: #{e.message}"
      query
    end

    def apply_label_filter(query)
      filter = trigger_conditions.dig('label_filter')

      if filter&.dig('enabled') && filter['labels'].present?
        query.where(
          "string_to_array(conversations.cached_label_list, ', ') && ARRAY[?]::text[]",
          filter['labels']
        )
      else
        query
      end
    end
  end
end
