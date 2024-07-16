class V2::InvoicesMetricsBuilder
  include DateRangeHelper

  def initialize(account, params)
    @account = account
    @params = params
    @group_by = params[:group_by] || 'month' # default to 'month'
  end

  def invoices_metrics
    results = {}
    start_date = range.first.to_date
    end_date = range.last.to_date

    periods_in_range(start_date, end_date).each do |period_start|
      results[period_label(period_start)] = calculate_metrics(period_start)
    end

    results
  end

  private

  def periods_in_range(start_date, end_date)
    case @group_by
    when 'day'
      (start_date..end_date).to_a
    when 'year'
      (start_date.year..end_date.year).map { |year| Date.new(year, 1, 1) }
    else # month
      (start_date..end_date).select { |d| d.day == 1 }
    end
  end

  def period_label(period_start)
    case @group_by
    when 'day'
      period_start.strftime('%d %B %Y')
    when 'year'
      period_start.year.to_s
    else # month
      period_start.strftime('%B %Y')
    end
  end

  def calculate_metrics(period_start)
    period_end = period_end(period_start)

    total_conversations = count_conversations(period_start, period_end)
    total_agents = count_agents(period_start, period_end)
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

  def period_end(period_start)
    case @group_by
    when 'day'
      period_start.end_of_day
    when 'year'
      period_start.end_of_year
    else # month
      period_start.end_of_month
    end
  end

  def count_conversations(start_date, end_date)
    @account.conversations.where(created_at: start_date..end_date).count
  end

  def count_agents(start_date, end_date)
    @account.agents.where(created_at: start_date..end_date).count
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
    since = @params[:since].present? ? parse_date_time(@params[:since]) : default_start_date
    until_date = @params[:until].present? ? parse_date_time(@params[:until]) : default_end_date
    since..until_date
  end

  def default_start_date
    [@account.conversations.minimum(:created_at), @account.agents.minimum(:created_at)].compact.min || DateTime.now.beginning_of_day
  end

  def default_end_date
    [@account.conversations.maximum(:created_at), @account.agents.maximum(:created_at)].compact.max || DateTime.now.end_of_day
  end
end
