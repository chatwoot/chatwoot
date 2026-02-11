module ReportingEvents::RollupService
  def self.perform(reporting_event)
    new(reporting_event).perform
  end

  def self.new(reporting_event)
    Performer.new(reporting_event)
  end

  class Performer
    def initialize(reporting_event)
      @reporting_event = reporting_event
      @account = reporting_event.account
    end

    def perform
      return unless rollup_enabled?

      dimensions.each do |dimension_type, dimension_id|
        next if dimension_id.nil?

        metrics_for_event.each do |metric, metric_data|
          upsert_rollup(dimension_type, dimension_id, metric, metric_data)
        end
      end
    end

    private

    def rollup_enabled?
      @account.reporting_timezone.present?
    end

    def event_date
      @event_date ||= @reporting_event.created_at.in_time_zone(@account.reporting_timezone).to_date
    end

    def dimensions
      {
        account: @account.id,
        agent: @reporting_event.user_id,
        inbox: @reporting_event.inbox_id,
        team: team_id
      }
    end

    def team_id
      return nil if @reporting_event.conversation_id.blank?

      @team_id ||= @reporting_event.conversation&.team_id
    end

    def metrics_for_event
      case @reporting_event.name
      when 'conversation_resolved'
        conversation_resolved_metrics
      when 'first_response'
        first_response_metrics
      when 'reply_time'
        reply_time_metrics
      when 'conversation_bot_resolved'
        bot_resolutions_metrics
      when 'conversation_bot_handoff'
        bot_handoffs_metrics
      else
        {}
      end
    end

    def conversation_resolved_metrics
      {
        resolutions_count: { count: 1, sum_value: 0, sum_value_business_hours: 0 },
        resolution_time: {
          count: 1,
          sum_value: @reporting_event.value,
          sum_value_business_hours: @reporting_event.value_in_business_hours
        }
      }
    end

    def first_response_metrics
      {
        first_response: {
          count: 1,
          sum_value: @reporting_event.value,
          sum_value_business_hours: @reporting_event.value_in_business_hours
        }
      }
    end

    def reply_time_metrics
      {
        reply_time: {
          count: 1,
          sum_value: @reporting_event.value,
          sum_value_business_hours: @reporting_event.value_in_business_hours
        }
      }
    end

    def bot_resolutions_metrics
      {
        bot_resolutions_count: { count: 1, sum_value: 0, sum_value_business_hours: 0 }
      }
    end

    def bot_handoffs_metrics
      {
        bot_handoffs_count: { count: 1, sum_value: 0, sum_value_business_hours: 0 }
      }
    end

    def upsert_rollup(dimension_type, dimension_id, metric, metric_data)
      # rubocop:disable Rails/SkipsModelValidations
      ReportingEventRollup.upsert(
        {
          account_id: @account.id,
          date: event_date,
          dimension_type: dimension_type,
          dimension_id: dimension_id,
          metric: metric,
          count: metric_data[:count],
          sum_value: metric_data[:sum_value],
          sum_value_business_hours: metric_data[:sum_value_business_hours],
          created_at: Time.current,
          updated_at: Time.current
        },
        unique_by: [:account_id, :date, :dimension_type, :dimension_id, :metric],
        on_duplicate: Arel.sql(
          'count = count + EXCLUDED.count, ' \
          'sum_value = sum_value + EXCLUDED.sum_value, ' \
          'sum_value_business_hours = sum_value_business_hours + EXCLUDED.sum_value_business_hours, ' \
          'updated_at = EXCLUDED.updated_at'
        )
      )
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
