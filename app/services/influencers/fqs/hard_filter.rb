class Influencers::Fqs::HardFilter
  def initialize(profile)
    @profile = profile
  end

  # Returns array of warning strings (empty = no warnings)
  def warnings
    checks = base_checks
    checks.concat(audience_checks) if @profile.report_available?

    checks.filter_map { |passed, message| message unless passed }
  end

  private

  def base_checks
    [
      check_er_minimum,
      check_er_maximum,
      check_inactive,
      check_follow_ratio,
      check_growth_spike,
      check_growth_monthly,
      check_likes_vs_views,
      check_likes_comments_ratio
    ]
  end

  def audience_checks
    [
      check_suspicious_audience,
      check_audience_credibility,
      check_growth_3m
    ]
  end

  def check_er_minimum
    er = @profile.engagement_rate.to_f
    return [true, nil] if er >= 0.01

    [false, "ER #{format_pct(er)} below 1% minimum"]
  end

  def check_er_maximum
    er = @profile.engagement_rate.to_f
    return [true, nil] if er <= 0.15

    [false, "ER #{format_pct(er)} exceeds 15% — likely bought engagement"]
  end

  def check_inactive
    last_posted = @profile.last_post_at
    return [true, nil] if last_posted.nil?
    return [true, nil] if last_posted >= 60.days.ago

    [false, "Last post #{last_posted.to_date} — inactive for over 60 days"]
  end

  def check_follow_ratio
    followers = @profile.followers_count.to_f
    following = @profile.following_count.to_f
    return [true, nil] if followers.zero?

    ratio = following / followers
    return [true, nil] if ratio <= 0.8

    [false, "Following:Followers ratio #{format('%.2f', ratio)} exceeds 0.8"]
  end

  def check_growth_spike
    stat_history = extract_stat_history
    return [true, nil] if stat_history.size < 2

    recent = stat_history.last(2)
    prev_followers = recent[0]['followers'].to_f
    curr_followers = recent[1]['followers'].to_f
    return [true, nil] if prev_followers.zero?

    weekly_growth = (curr_followers - prev_followers) / prev_followers
    return [true, nil] if weekly_growth <= 0.20

    [false, "Growth spike #{format_pct(weekly_growth)} in recent period — possible bought followers"]
  end

  # Monthly growth > 5% warning
  def check_growth_monthly
    growth = extract_monthly_growth
    return [true, nil] if growth.nil?

    pct = growth * 100
    return [true, nil] if pct <= 5.0

    [false, "Monthly growth #{format('%.1f', pct)}% exceeds 5% — suspicious growth"]
  end

  def check_likes_vs_views
    avg_likes = @profile.avg_likes.to_f
    avg_views = @profile.avg_reel_views.to_f
    return [true, nil] if avg_views.zero? || avg_likes.zero?
    return [true, nil] if avg_likes <= avg_views * 2

    [false, "Avg likes (#{avg_likes.round}) > 2x avg views (#{avg_views.round}) — likely bought likes"]
  end

  def check_likes_comments_ratio
    avg_likes = @profile.avg_likes.to_f
    avg_comments = @profile.avg_comments.to_f
    return [true, nil] if avg_comments.zero? || avg_likes.zero?

    ratio = avg_likes / avg_comments
    return [true, nil] if ratio <= 500

    [false, "Likes:Comments ratio #{ratio.round}:1 exceeds 500:1 — bot engagement suspected"]
  end

  def check_suspicious_audience
    audience_types = extract_audience_types
    return [true, nil] if audience_types.empty?

    total = suspicious_audience_weight(audience_types)
    return [true, nil] if total <= 0.65

    [false, "Mass + suspicious audience #{format_pct(total)} exceeds 65%"]
  end

  def check_audience_credibility
    credibility = @profile.audience_credibility.to_f
    return [true, nil] if credibility.zero? && @profile.audience_credibility.nil?
    return [true, nil] if credibility >= 0.75

    [false, "Audience credibility #{format_pct(credibility)} below 75%"]
  end

  def check_growth_3m
    stat_history = extract_stat_history
    return [true, nil] if stat_history.size < 4

    oldest = stat_history[-4]['followers'].to_f
    newest = stat_history[-1]['followers'].to_f
    return [true, nil] if oldest.zero?

    growth_3m = (newest - oldest) / oldest
    return [true, nil] if growth_3m <= 0.50

    [false, "3-month growth #{format_pct(growth_3m)} exceeds 50% — unnatural growth"]
  end

  def extract_monthly_growth
    return @profile.follower_growth_rate if @profile.follower_growth_rate.present?

    history = extract_stat_history
    return nil if history.size < 2

    oldest = history.first&.dig('followers').to_f
    return nil if oldest.zero?

    newest = history.last&.dig('followers').to_f
    months = [history.size - 1, 1].max
    ((newest - oldest) / oldest) / months
  end

  def suspicious_audience_weight(types)
    codes = %w[mass_followers suspicious]
    types.select { |t| codes.include?(t['code']) || t['name'].to_s.downcase.match?(/mass|suspicious/) }.sum { |t| t['weight'].to_f }
  end

  def extract_stat_history
    history = @profile.stat_history
    return history if history.is_a?(Array) && history.present?

    report_data = @profile.raw_report_data || {}
    fallback = report_data.dig('user_profile', 'stat_history') || []
    fallback.is_a?(Array) ? fallback : []
  end

  def extract_audience_types
    types = @profile.audience_types
    return types if types.is_a?(Array) && types.present?

    report_data = @profile.raw_report_data || {}
    fallback = report_data.dig('audience_likers', 'data', 'audience_types') || []
    fallback.is_a?(Array) ? fallback : []
  end

  def format_pct(value)
    "#{format('%.1f', value * 100)}%"
  end
end
