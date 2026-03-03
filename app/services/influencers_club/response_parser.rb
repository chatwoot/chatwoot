class InfluencersClub::ResponseParser
  # Parse discovery results into search result format
  def self.parse_discovery_result(account)
    return if account.blank?

    profile = account['profile'] || {}
    {
      username: profile['username'],
      fullname: profile['full_name'],
      platform: 'instagram',
      profile_picture_url: profile['picture'],
      followers_count: profile['followers'],
      engagement_rate: profile['engagement_percent'].to_f / 100.0,
      external_search_id: account['user_id']&.to_s
    }.compact
  end

  # Parse full enrich response into InfluencerProfile attributes
  def self.parse_enrich(data)
    return if data.blank?

    ig = data.dig('result', 'instagram') || {}
    audience_data = ig.dig('audience', 'audience_followers', 'data') || ig.dig('audience', 'audience_likers', 'data') || {}
    reels = ig['reels'] || {}

    profile_attrs = parse_profile_fields(ig, reels)
    audience_attrs = parse_audience_fields(audience_data)
    growth = parse_growth(ig['creator_follower_growth'])

    result = data['result'] || {}

    profile_attrs.merge(audience_attrs).merge(
      follower_growth_rate: growth[:monthly_growth],
      stat_history: ig['creator_follower_growth'] || {},
      recent_reels: extract_reels(ig['post_data']),
      last_post_at: parse_date(ig['most_recent_post_date']),
      target_market: ig['country']&.upcase,
      raw_report_data: data,
      _contact_email: result['email'].presence
    ).compact
  end

  def self.parse_profile_fields(ig, reels)
    {
      username: ig['username'],
      fullname: ig['full_name'],
      platform: 'instagram',
      profile_url: "https://www.instagram.com/#{ig['username']}/",
      profile_picture_url: ig['profile_picture'],
      bio: ig['biography'],
      is_verified: ig['is_verified'] || false,
      followers_count: ig['follower_count'],
      following_count: ig['following_count'],
      posts_count: ig['media_count'],
      engagement_rate: ig['engagement_percent'].to_f / 100.0,
      avg_likes: ig['avg_likes'],
      avg_comments: ig['avg_comments'],
      avg_reel_views: reels['avg_view_count'],
      median_reel_views: reels['median_view_count'],
      hidden_like_posts_rate: detect_hidden_likes(ig),
      paid_post_performance: ig['has_paid_partnership'] ? 1.0 : 0.0,
      top_hashtags: normalize_hashtags(ig['hashtags_count']),
      interests: normalize_interests(ig['niche_class'])
    }
  end
  private_class_method :parse_profile_fields

  def self.parse_audience_fields(audience_data)
    return {} if audience_data.blank?

    reachability = calculate_reachability(audience_data['audience_reachability'] || [])
    {
      audience_credibility: audience_data['audience_credibility'],
      audience_credibility_class: audience_data['credibility_class'],
      audience_reachability: reachability,
      audience_genders: audience_data['audience_genders'] || {},
      audience_ages: audience_data['audience_ages'] || {},
      audience_geo: audience_data['audience_geo'] || {},
      audience_interests: audience_data['audience_interests'] || {},
      audience_brand_affinity: audience_data['audience_brand_affinity'] || {},
      audience_types: audience_data['audience_types'] || {}
    }
  end
  private_class_method :parse_audience_fields

  def self.parse_growth(growth_data)
    return { monthly_growth: nil } if growth_data.blank?

    # Pre-computed 3-month growth percentage -> monthly rate
    three_month_pct = growth_data['3_months_ago'].to_f
    { monthly_growth: (three_month_pct / 3.0 / 100.0).round(4) }
  end
  private_class_method :parse_growth

  def self.detect_hidden_likes(ig)
    posts = ig['post_data']
    return 0.0 if posts.blank?

    total = posts.size.to_f
    hidden = posts.count { |p| p.dig('engagement', 'likes').to_i <= 3 }
    hidden / total
  end
  private_class_method :detect_hidden_likes

  def self.normalize_hashtags(hashtags_count)
    return [] if hashtags_count.blank?

    hashtags_count.map { |h| { 'tag' => h['name'], 'weight' => h['count'] } }
  end
  private_class_method :normalize_hashtags

  def self.normalize_interests(niche_class)
    return [] if niche_class.blank?

    Array(niche_class).map { |name| { 'name' => name } }
  end
  private_class_method :normalize_interests

  def self.calculate_reachability(reachability_data)
    return 0.0 if reachability_data.blank?

    reachable_codes = %w[-500 500-1000]
    reachability_data.select { |r| reachable_codes.include?(r['code'].to_s) }.sum { |r| r['weight'].to_f }
  end
  private_class_method :calculate_reachability

  # Extract reels from post_data (filter by product_type)
  def self.extract_reels(post_data)
    return [] if post_data.blank?

    post_data
      .select { |p| p['product_type']&.include?('reel') || p['product_type']&.include?('clip') }
      .first(5)
      .map do |reel|
        engagement = reel['engagement'] || {}
        media = Array(reel['media']).first || {}
        {
          url: reel['post_url'],
          thumbnail_url: media['url'],
          views: engagement['view_count'] || engagement['views'] || engagement['plays'],
          likes: engagement['likes'],
          comments: engagement['comments'],
          timestamp: reel['created_at']
        }
      end
  end
  private_class_method :extract_reels

  def self.parse_date(date_string)
    return nil if date_string.blank?

    Date.parse(date_string).to_time
  rescue ArgumentError
    nil
  end
  private_class_method :parse_date
end
