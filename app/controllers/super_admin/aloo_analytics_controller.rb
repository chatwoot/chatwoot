class SuperAdmin::AlooAnalyticsController < SuperAdmin::ApplicationController
  include ActionView::Helpers::NumberHelper

  def index
    @stats = gather_stats
    @chart_data = gather_chart_data
  end

  private

  def gather_stats
    {
      assistants_count: number_with_delimiter(aloo_assistants_count),
      documents_count: number_with_delimiter(aloo_documents_count),
      embeddings_count: number_with_delimiter(aloo_embeddings_count),
      executions_count: number_with_delimiter(executions_count),
      total_input_tokens: number_with_delimiter(total_input_tokens),
      total_output_tokens: number_with_delimiter(total_output_tokens),
      total_conversations: number_with_delimiter(aloo_conversations_count),
      failed_executions_count: number_with_delimiter(failed_executions_count),
      success_rate: calculate_success_rate
    }
  end

  def gather_chart_data
    return [] unless execution_table_exists?

    # Use gem's Execution model for chart data
    RubyLLM::Agents::Execution
      .by_agent('ConversationAgent')
      .where('created_at > ?', 30.days.ago)
      .group_by_day(:created_at)
      .count
      .to_a
  end

  def aloo_assistants_count
    return 0 unless table_exists?('aloo_assistants')

    Aloo::Assistant.count
  end

  def aloo_documents_count
    return 0 unless table_exists?('aloo_documents')

    Aloo::Document.count
  end

  def aloo_embeddings_count
    return 0 unless table_exists?('aloo_embeddings')

    Aloo::Embedding.count
  end

  def executions_count
    return 0 unless execution_table_exists?

    agent_executions.count
  end

  def failed_executions_count
    return 0 unless execution_table_exists?

    agent_executions.failed.count
  end

  def total_input_tokens
    return 0 unless execution_table_exists?

    agent_executions.sum(:input_tokens)
  end

  def total_output_tokens
    return 0 unless execution_table_exists?

    agent_executions.sum(:output_tokens)
  end

  def aloo_conversations_count
    return 0 unless execution_table_exists?

    agent_executions.count
  end

  def calculate_success_rate
    return '0%' unless execution_table_exists?

    total = agent_executions.count
    return '0%' if total.zero?

    successful = agent_executions.successful.count
    "#{((successful.to_f / total) * 100).round(1)}%"
  end

  def agent_executions
    @agent_executions ||= RubyLLM::Agents::Execution
                          .by_agent('ConversationAgent')
                          .where('created_at > ?', 30.days.ago)
  end

  def execution_table_exists?
    ActiveRecord::Base.connection.table_exists?('ruby_llm_agents_executions')
  end

  def table_exists?(table_name)
    ActiveRecord::Base.connection.table_exists?(table_name)
  end
end
