class V2::MonthlyInvoicesBuilder
  include DateRangeHelper

  def initialize(account, params)
    @account = account
    @params = params
  end

  def invoices_metrics
    results = {}
    start_date = range.first.beginning_of_month
    end_date = range.last.end_of_month

    (start_date..end_date).select { |d| d.day == 1 }.each do |month_start|
      results[month_start.strftime('%B %Y')] = calculate_monthly_metrics(month_start)
    end

    results
  end

  private

  def calculate_monthly_metrics(month_start)
    month_end = month_start.end_of_month

    total_conversations = count_monthly_conversations(month_start, month_end)
    total_agents = count_monthly_agents(month_start, month_end)
    base_price = @account.product.price

    product_details = extract_product_details(@account.product.details)

    extra_conversation_cost = calculate_extra_cost(total_conversations, product_details[:conversation_limit],
                                                   product_details[:extra_conversation_price])
    extra_agent_cost = calculate_extra_cost(total_agents, product_details[:agent_limit], product_details[:extra_agent_price])

    total_price = calculate_total_price(base_price, extra_conversation_cost, extra_agent_cost)

    metrics = {
      total_conversations: total_conversations,
      total_agents: total_agents,
      base_price: base_price,
      extra_conversation_cost: extra_conversation_cost,
      extra_agent_cost: extra_agent_cost,
      total_price: total_price
    }

    build_metrics_hash(metrics)
  end

  def count_monthly_conversations(month_start, month_end)
    @account.conversations.where(created_at: month_start..month_end).count
  end

  def count_monthly_agents(month_start, month_end)
    @account.agents.where(created_at: month_start..month_end).count
  end

  def calculate_extra_cost(total_items, limit, extra_price)
    [total_items - limit, 0].max * extra_price
  end

  def calculate_total_price(base_price, extra_conversation_cost, extra_agent_cost)
    base_price + extra_conversation_cost + extra_agent_cost
  end

  def build_metrics_hash(metrics)
    {
      total_conversations: metrics[:total_conversations],
      total_agents: metrics[:total_agents],
      base_price: metrics[:base_price],
      extra_conversation_cost: metrics[:extra_conversation_cost],
      extra_agent_cost: metrics[:extra_agent_cost],
      total_price: metrics[:total_price]
    }
  end

  def extract_product_details(details)
    {
      conversation_limit: details['number_of_conversations'] || 0,
      agent_limit: details['number_of_agents'] || 0,
      extra_conversation_price: details['extra_conversation_cost'] || 0,
      extra_agent_price: details['extra_agent_cost'] || 0
    }
  end

  def range
    parse_date_time(@params[:since])..parse_date_time(@params[:until])
  end
end
