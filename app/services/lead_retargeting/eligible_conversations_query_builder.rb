# frozen_string_literal: true

module LeadRetargeting
  class EligibleConversationsQueryBuilder
    ALLOWED_DATE_COLUMNS = {
      'conversation_created_at' => 'conversations.created_at',
      'inactive_days' => 'conversations.last_activity_at'
    }.freeze

    def self.call(account_id:, inbox_id:, trigger_conditions: {}, include_cancelled: true, stop_on_contact_reply: false, sequence_id: nil)
      new(
        account_id: account_id,
        inbox_id: inbox_id,
        trigger_conditions: trigger_conditions,
        include_cancelled: include_cancelled,
        stop_on_contact_reply: stop_on_contact_reply,
        sequence_id: sequence_id
      ).build
    end

    def initialize(account_id:, inbox_id:, trigger_conditions:, include_cancelled:, stop_on_contact_reply:, sequence_id:)
      @account_id = account_id
      @inbox_id = inbox_id
      @trigger_conditions = trigger_conditions || {}
      @include_cancelled = include_cancelled
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

    attr_reader :account_id, :inbox_id, :trigger_conditions, :include_cancelled, :stop_on_contact_reply, :sequence_id

    def base_query
      Conversation.where(account_id: account_id, inbox_id: inbox_id)
    end

    def apply_enrollment_filter(query)
      query = query.left_joins(:conversation_follow_up)

      if sequence_id.present?
        if include_cancelled
          query.where(
            'conversation_follow_ups.id IS NULL OR ' \
            '(conversation_follow_ups.lead_follow_up_sequence_id = ? OR conversation_follow_ups.status = ?)',
            sequence_id,
            'cancelled'
          )
        else
          query.where(conversation_follow_up: { id: nil })
        end
      else
        if include_cancelled
          query.where('conversation_follow_ups.id IS NULL OR conversation_follow_ups.status = ?', 'cancelled')
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
        Rails.logger.info "Applying default status filter: query pending = #{query.pluck(:id)}"
        query.where('conversations.status' => %i[open pending])
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
          apply_last_message_date_filter(query, filter)
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

    def apply_last_message_date_filter(query, filter)
      case filter['operator']
      when 'older_than'
        cutoff_date = filter['value'].to_i.days.ago
        query.where(
          'conversations.id IN (
            SELECT conversation_id
            FROM messages
            WHERE messages.conversation_id = conversations.id
            GROUP BY conversation_id
            HAVING MAX(messages.created_at) < ?
          )',
          cutoff_date
        )
      when 'newer_than'
        cutoff_date = filter['value'].to_i.days.ago
        query.where(
          'conversations.id IN (
            SELECT conversation_id
            FROM messages
            WHERE messages.conversation_id = conversations.id
            GROUP BY conversation_id
            HAVING MAX(messages.created_at) > ?
          )',
          cutoff_date
        )
      when 'between'
        from_date = Date.parse(filter['from_date']).beginning_of_day
        to_date = Date.parse(filter['to_date']).end_of_day
        query.where(
          'conversations.id IN (
            SELECT conversation_id
            FROM messages
            WHERE messages.conversation_id = conversations.id
            GROUP BY conversation_id
            HAVING MAX(messages.created_at) BETWEEN ? AND ?
          )',
          from_date,
          to_date
        )
      else
        query
      end
    rescue ArgumentError => e
      Rails.logger.error "Invalid date in last_message_at filter: #{e.message}"
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
