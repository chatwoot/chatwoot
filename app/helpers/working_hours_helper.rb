# rubocop:disable Naming/MethodParameterName
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable  Metrics/ParameterLists
# rubocop:disable Lint/DuplicateBranch
module WorkingHoursHelper
  SHOP_URL_TTL = 24.hours
  WORKING_HOURS_TTL = 12.hours

  def in_working_hours(account_id, created_at)
    shop_url = fetch_shop_url(account_id)
    return true if shop_url.blank?

    working_hours = fetch_working_hours(shop_url)
    return true if working_hours.blank?

    check_working_hours(working_hours, created_at)
  end

  def fetch_shop_url(account_id)
    cache_key = "shop_url:#{account_id}"
    cached_url = Redis::Alfred.get(cache_key)
    return cached_url if cached_url.present?

    url = fetch_shop_url_from_api(account_id)
    Redis::Alfred.setex(cache_key, url, SHOP_URL_TTL) if url.present?
    url
  end

  private

  def fetch_shop_url_from_api(account_id)
    response = HTTParty.get("https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/accountDetails/#{account_id}")
    return nil unless response.success?

    JSON.parse(response.body)['accountDetails']['shopUrl']
  rescue StandardError => e
    Rails.logger.error "Error fetching shop URL: #{e.message}"
    nil
  end

  def fetch_working_hours(shop_url)
    cache_key = "working_hours:#{shop_url}"
    cached_hours = Redis::Alfred.get(cache_key)
    return JSON.parse(cached_hours) if cached_hours.present?

    hours = fetch_working_hours_from_api(shop_url)
    Redis::Alfred.setex(cache_key, hours.to_json, WORKING_HOURS_TTL) if hours.present?
    hours
  end

  def fetch_working_hours_from_api(shop_url)
    response = HTTParty.get(
      'https://mcfsmik3g0.execute-api.us-east-1.amazonaws.com/chatbot/botConfig',
      query: { shopUrl: shop_url }
    )
    return nil unless response.success?

    JSON.parse(response.body)['botConfig']['config']['workingHours']
  rescue StandardError => e
    Rails.logger.error "Error fetching working hours: #{e.message}"
    nil
  end

  # Convert timestamp to IST
  def get_ist_time(timestamp)
    # Convert to IST (UTC +5:30)
    ist_time = timestamp.in_time_zone('Asia/Kolkata')

    {
      hours_ist: ist_time.hour,
      minutes_ist: ist_time.min,
      day_ist: ist_time.wday
    }
  end

  def check_time(h, m, a, b, c, d)
    h = h.to_i
    m = m.to_i
    a = a.to_i
    b = b.to_i
    c = c.to_i
    d = d.to_i

    Rails.logger.debug { "checkTime h=#{h} m=#{m} a=#{a} b=#{b} c=#{c} d=#{d}" }

    if a > c || (a == c && b > d)
      check_time(h, m, a, b, 24, 0) || check_time(h, m, 0, 0, c, d)
    elsif h > a && h < c
      true
    elsif h == a && m >= b
      true
    elsif h == c && m <= d
      true
    else
      false
    end
  end

  def check_working_hours(working_hours, timestamp)
    return true if working_hours.blank?

    time_data = get_ist_time(timestamp)
    day = time_data[:day_ist].to_s

    Rails.logger.debug { "Day: #{day}" }

    time_slots = working_hours[day]
    return false if time_slots.blank? || !time_slots['enabled']

    time_slots['slots'].any? do |time_slot|
      check_time(
        time_data[:hours_ist],
        time_data[:minutes_ist],
        time_slot.dig('startTime', 'hours'),
        time_slot.dig('startTime', 'minutes'),
        time_slot.dig('endTime', 'hours'),
        time_slot.dig('endTime', 'minutes')
      )
    end
  end
end
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/ParameterLists
# rubocop:enable Naming/MethodParameterName
# rubocop:enable Lint/DuplicateBranch
