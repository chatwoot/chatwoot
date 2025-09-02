class SearchPerformanceMonitor
  SLOW_QUERY_THRESHOLD = 300 # milliseconds
  VERY_SLOW_QUERY_THRESHOLD = 1000 # milliseconds

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    
    # Only monitor search-related requests
    return @app.call(env) unless search_request?(request)

    start_time = Time.current
    status, headers, response = @app.call(env)
    end_time = Time.current

    duration = ((end_time - start_time) * 1000).round(2)
    
    log_search_performance(request, duration, status)
    track_search_metrics(request, duration, status)
    
    # Add performance headers
    headers['X-Search-Time'] = duration.to_s
    headers['X-Search-Threshold'] = SLOW_QUERY_THRESHOLD.to_s

    [status, headers, response]
  end

  private

  def search_request?(request)
    request.path.include?('/search') || 
    request.path.include?('/advanced_search')
  end

  def log_search_performance(request, duration, status)
    log_level = determine_log_level(duration)
    
    search_info = extract_search_info(request)
    
    message = "SearchPerformance: #{request.method} #{request.path} " \
              "#{status} #{duration}ms"
    
    details = {
      path: request.path,
      method: request.method,
      duration: duration,
      status: status,
      query: search_info[:query],
      search_type: search_info[:search_type],
      filters_count: search_info[:filters_count],
      user_agent: request.user_agent,
      remote_ip: request.remote_ip
    }

    case log_level
    when :error
      Rails.logger.error("#{message} - VERY SLOW QUERY", details)
    when :warn  
      Rails.logger.warn("#{message} - SLOW QUERY", details)
    else
      Rails.logger.info(message, details)
    end
  end

  def track_search_metrics(request, duration, status)
    search_info = extract_search_info(request)
    
    # Track with built-in metrics if available
    if defined?(ActiveSupport::Notifications)
      ActiveSupport::Notifications.instrument('search.performance', {
        duration: duration,
        status: status,
        search_type: search_info[:search_type],
        query_present: search_info[:query].present?,
        filters_count: search_info[:filters_count],
        slow_query: duration > SLOW_QUERY_THRESHOLD,
        very_slow_query: duration > VERY_SLOW_QUERY_THRESHOLD
      })
    end

    # Track with Prometheus if available
    if defined?(Prometheus) && defined?(PrometheusExporter::Metric)
      labels = {
        search_type: search_info[:search_type] || 'unknown',
        status: status.to_s,
        slow: duration > SLOW_QUERY_THRESHOLD ? 'true' : 'false'
      }

      PrometheusExporter::Metric::Counter.new(
        'chatwoot_search_requests_total',
        'Total number of search requests'
      ).increment(labels)

      PrometheusExporter::Metric::Histogram.new(
        'chatwoot_search_duration_seconds',
        'Search request duration in seconds',
        buckets: [0.1, 0.3, 0.5, 1.0, 2.0, 5.0]
      ).observe(duration / 1000.0, labels)
    end

    # Track slow queries separately
    if duration > SLOW_QUERY_THRESHOLD
      track_slow_query(request, search_info, duration)
    end
  end

  def track_slow_query(request, search_info, duration)
    # Store slow query data for analysis
    slow_query_data = {
      timestamp: Time.current.to_f,
      path: request.path,
      duration: duration,
      query: search_info[:query],
      search_type: search_info[:search_type],
      filters_count: search_info[:filters_count],
      user_agent: request.user_agent,
      remote_ip: request.remote_ip
    }

    # Store in Redis for real-time monitoring
    if defined?(Redis) && Rails.application.config.respond_to?(:redis)
      begin
        redis = Rails.application.config.redis
        key = "chatwoot:slow_searches:#{Date.current.strftime('%Y-%m-%d')}"
        
        redis.lpush(key, slow_query_data.to_json)
        redis.ltrim(key, 0, 99) # Keep only latest 100 slow queries per day
        redis.expire(key, 7.days.to_i) # Expire after 7 days
      rescue => e
        Rails.logger.error("Failed to store slow query data: #{e.message}")
      end
    end

    # Alert if very slow
    if duration > VERY_SLOW_QUERY_THRESHOLD
      alert_very_slow_query(slow_query_data)
    end
  end

  def alert_very_slow_query(query_data)
    # Send alerts for very slow queries
    message = "Very slow search query detected: #{query_data[:duration]}ms"
    
    # Log critical alert
    Rails.logger.error("CRITICAL: #{message}", query_data)

    # Send to error tracking service if available
    if defined?(Sentry)
      Sentry.capture_message(message, {
        level: :warning,
        extra: query_data,
        tags: { component: 'search_performance' }
      })
    elsif defined?(Bugsnag)
      Bugsnag.notify(RuntimeError.new(message)) do |report|
        report.severity = 'warning'
        report.add_metadata(:search_performance, query_data)
      end
    end

    # Send to Slack if webhook configured
    if ENV['SLACK_PERFORMANCE_WEBHOOK'].present?
      send_slack_alert(message, query_data)
    end
  end

  def send_slack_alert(message, query_data)
    begin
      webhook_url = ENV['SLACK_PERFORMANCE_WEBHOOK']
      payload = {
        text: message,
        attachments: [{
          color: 'warning',
          fields: [
            { title: 'Duration', value: "#{query_data[:duration]}ms", short: true },
            { title: 'Query', value: query_data[:query] || 'N/A', short: true },
            { title: 'Search Type', value: query_data[:search_type] || 'N/A', short: true },
            { title: 'Filters', value: query_data[:filters_count].to_s, short: true },
            { title: 'Path', value: query_data[:path], short: false }
          ]
        }]
      }

      Net::HTTP.post_form(
        URI(webhook_url),
        { payload: payload.to_json }
      )
    rescue => e
      Rails.logger.error("Failed to send Slack alert: #{e.message}")
    end
  end

  def extract_search_info(request)
    params = request.params
    
    # Count active filters
    filter_params = %w[
      channel_types inbox_ids agent_ids team_ids tags labels status priority
      message_types sender_types sentiment sla_status contact_segments
      date_from date_to custom_attributes has_attachments unread_only
      assigned_only unassigned_only
    ]
    
    filters_count = filter_params.count { |param| 
      value = params[param]
      value.present? && !(value.is_a?(Array) && value.empty?)
    }

    {
      query: params['q'] || params['query'],
      search_type: extract_search_type(request),
      filters_count: filters_count
    }
  end

  def extract_search_type(request)
    case request.path
    when /\/conversations$/
      'conversations'
    when /\/messages$/
      'messages'  
    when /\/contacts$/
      'contacts'
    when /\/articles$/
      'articles'
    else
      'all'
    end
  end

  def determine_log_level(duration)
    if duration > VERY_SLOW_QUERY_THRESHOLD
      :error
    elsif duration > SLOW_QUERY_THRESHOLD
      :warn
    else
      :info
    end
  end
end