class V2::Reports::Conversations::MetricBuilder < V2::Reports::Conversations::BaseReportBuilder
  def summary
    result = {
      conversations_count: count('conversations_count'),
      outgoing_messages_count: count('outgoing_messages_count'),
      avg_first_response_time: count('avg_first_response_time'),
      avg_resolution_time: count('avg_resolution_time'),
      incoming_messages_count: 0,
      resolutions_count: count('resolutions_count'),
      reply_time: count('reply_time')
    }

    # Only include incoming_messages_count for non-agent summaries
    result[:incoming_messages_count] = count('incoming_messages_count') unless params[:type] == :agent

    result
  end

  def bot_summary
    {
      bot_resolutions_count: count('bot_resolutions_count'),
      bot_handoffs_count: count('bot_handoffs_count')
    }
  end

  private

  def count(metric)
    builder_class(metric).new(account, builder_params(metric)).aggregate_value
  end

  def builder_params(metric)
    params.merge({ metric: metric })
  end
end
