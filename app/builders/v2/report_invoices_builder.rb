class V2::ReportInvoicesBuilder
  include DateRangeHelper

  attr_reader :account, :params, :group_by, :product, :account_plan

  def initialize(account, params)
    @account = account
    @account_plan = @account.account_plan
    @product = @account_plan.product
    @params = params
    @group_by = params[:group_by] || 'month' # default to 'month'
  end

  def invoices_metrics
    values = []
    total_summary = initialize_total_summary

    start_date = range.first.to_date
    end_date = range.last.to_date

    periods_in_range_for_group_by(group_by, start_date, end_date).each do |period_start|
      period_metrics = calculate_metrics(period_start)
      update_total_summary(total_summary, period_metrics)
      values << period_metrics.to_h.merge(timestamp: period_start.to_time.to_i)
    end

    {
      values: values,
      total_summary: total_summary
    }
  end

  private

  def calculate_metrics(period_start)
    period_end = period_end_for_group_by(group_by, period_start)

    total_conversations = total_conversations(period_start, period_end)
    total_agents = total_agents(period_start, period_end)

    base_price = product.price

    product_details = extract_product_details(product.details)
    extra_conversation_cost = calculate_extra_cost(
      total_conversations,
      product_details[:conversation_limit] + account_plan.extra_conversations,
      product_details[:extra_conversation_price]
    )
    extra_agent_cost = calculate_extra_cost(
      total_agents,
      product_details[:agent_limit] + account_plan.extra_agents,
      product_details[:extra_agent_price]
    )
    total_price = calculate_total_price(base_price, extra_conversation_cost, extra_agent_cost)

    V2::MetricsData.new(
      total_conversations: total_conversations,
      total_agents: total_agents,
      base_price: base_price,
      extra_conversation_cost: extra_conversation_cost,
      extra_agent_cost: extra_agent_cost,
      total_price: total_price
    )
  end

  def total_conversations(start_date, end_date)
    account.conversations.where(created_at: start_date..end_date).count
  end

  def total_agents(start_date, end_date)
    account.agents.where(created_at: start_date..end_date).count
  end

  def count_agents(start_date, end_date)
    account.reporting_events
           .where(name: 'extra_agents', created_at: start_date..end_date)
           .sum(:value)
  end

  def calculate_extra_cost(total_items, limit, extra_price)
    [total_items - limit, 0].max * extra_price
  end

  def calculate_total_price(base_price, extra_conversation_cost, extra_agent_cost)
    base_price + extra_conversation_cost + extra_agent_cost
  end

  def extract_product_details(details)
    {
      conversation_limit: details['number_of_conversations'] || 0,
      agent_limit: details['number_of_agents'] || 0,
      extra_conversation_price: details['extra_conversation_cost'] || 0,
      extra_agent_price: details['extra_agent_cost'] || 0
    }
  end

  def update_total_summary(total_summary, period_metrics)
    total_summary[:total_conversations] += period_metrics.total_conversations
    total_summary[:total_agents] += period_metrics.total_agents
    total_summary[:base_price] += period_metrics.base_price
    total_summary[:extra_conversation_cost] += period_metrics.extra_conversation_cost
    total_summary[:extra_agent_cost] += period_metrics.extra_agent_cost
    total_summary[:total_price] += period_metrics.total_price
  end

  def initialize_total_summary
    {
      total_conversations: 0,
      total_agents: 0,
      base_price: 0.0,
      extra_conversation_cost: 0.0,
      extra_agent_cost: 0.0,
      total_price: 0.0
    }
  end

  def range
    since = params[:since].present? ? parse_date_time(params[:since]) : default_start_date
    until_date = params[:until].present? ? parse_date_time(params[:until]) : default_end_date
    since..until_date
  end

  def default_start_date
    [account.reporting_events.minimum(:created_at)].compact.min || DateTime.now.beginning_of_day
  end

  def default_end_date
    [account.reporting_events.maximum(:created_at)].compact.max || DateTime.now.end_of_day
  end
end
