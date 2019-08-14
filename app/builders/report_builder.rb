class ReportBuilder
  include CustomExceptions::Report

  # Usage
  #  rb = ReportBuilder.new a, { metric: 'conversations_count', type: :account, id: 1}
  #  rb = ReportBuilder.new a, { metric: 'avg_first_response_time', type: :agent, id: 1}

  IDENTITY_MAPPING = {
    account: AccountIdentity,
    agent: AgentIdentity
  }

  def initialize(account, params)
    @account = account
    @params = params
    @identity = get_identity
    @start_time, @end_time = validate_times
  end

  def build
    metric = @identity.send(@params[:metric])
    if metric.get.nil?
      metric.delete
      result = {}
    else
      result = metric.get_padded_range(@start_time, @end_time) || {}
    end
    formatted_hash(result)
  end

  private

  def get_identity
    identity_class = IDENTITY_MAPPING[@params[:type]]
    raise InvalidIdentity if identity_class.nil?

    @params[:id] = @account.id if identity_class == AccountIdentity
    identity_id = @params[:id]
    raise IdentityNotFound if identity_id.nil?

    tags = identity_class == AccountIdentity ? nil : { account_id: @account.id}
    identity = identity_class.new(identity_id, tags: tags)
    raise MetricNotFound if @params[:metric].blank?
    raise MetricNotFound unless identity.respond_to?(@params[:metric])
    identity
  end

  def validate_times
    start_time = @params[:since] || Time.now.end_of_day - 30.days
    end_time = @params[:until] || Time.now.end_of_day
    start_time = parse_date_time(start_time) rescue raise(InvalidStartTime)
    end_time = parse_date_time(end_time) rescue raise(InvalidEndTime)
    [start_time, end_time]
  end

  def parse_date_time(datetime)
    return datetime if datetime.is_a?(DateTime)
    return datetime.to_datetime if datetime.is_a?(Time) or datetime.is_a?(Date)
    DateTime.strptime(datetime,'%s')
  end

  def formatted_hash(hash)
    hash.inject([]) do |arr,p|
      arr << {value: p[1], timestamp: p[0]}
      arr
    end
  end
end
