class Influencers::Fqs::Stage1Scorer
  TIER_MEDIAN_ER = { nano: 0.04, micro: 0.025, mid: 0.015, macro: 0.01 }.freeze

  ER_QUALITY_MAX = 40
  REEL_VIEWS_MAX = 35
  GROWTH_MAX = 25
  MAX_TOTAL = 100

  def initialize(profile)
    @profile = profile
  end

  # Used by FqsCalculator for discovery-only scoring (only ER data available)
  def er_quality_score_only
    er_quality_score
  end

  def score
    breakdown = {
      er_quality: er_quality_score,
      reel_views: reel_views_score,
      growth: growth_score
    }

    { total: breakdown.values.sum, breakdown: breakdown }
  end

  private

  def er_quality_score
    return er_quality_degraded if @profile.hidden_likes?

    er = @profile.effective_er || compute_effective_er
    median = TIER_MEDIAN_ER[@profile.tier] || 0.025
    return 0 if median.zero?

    ratio = er / median
    er_base_score(ratio)
  end

  def er_quality_degraded
    followers = @profile.followers_count.to_f
    return 0 if followers.zero?

    comment_er = (@profile.avg_comments.to_f / followers) * 100

    if comment_er > 0.15
      25
    elsif comment_er > 0.10
      18
    elsif comment_er > 0.05
      12
    else
      5
    end
  end

  def er_base_score(ratio)
    if ratio >= 2.0
      40
    elsif ratio >= 1.5
      32
    elsif ratio >= 1.0
      24
    elsif ratio >= 0.7
      16
    elsif ratio >= 0.4
      8
    else
      0
    end
  end

  def compute_effective_er
    api_er = @profile.engagement_rate.to_f
    followers = @profile.followers_count.to_f
    return api_er if followers.zero?

    computed = (@profile.avg_likes.to_f + @profile.avg_comments.to_f) / followers
    [api_er, computed].max
  end

  def reel_views_score
    followers = @profile.followers_count.to_f
    views = @profile.median_reel_views.to_f.nonzero? || @profile.avg_reel_views.to_f
    return 0 if followers.zero? || views.zero?

    ratio = views / followers

    if ratio >= 3.0
      35
    elsif ratio >= 2.0
      28
    elsif ratio >= 1.0
      21
    elsif ratio >= 0.5
      14
    elsif ratio >= 0.2
      7
    else
      0
    end
  end

  def growth_score
    monthly_growth = extract_monthly_growth
    return 10 if monthly_growth.nil?

    pct = monthly_growth * 100

    if pct.between?(1.0, 5.0)
      25
    elsif pct.between?(0.5, 1.0)
      18
    elsif pct.between?(0.0, 0.5)
      10
    elsif pct > 5.0
      10
    elsif pct >= -2.0
      5
    else
      0
    end
  end

  def extract_monthly_growth
    return @profile.follower_growth_rate if @profile.follower_growth_rate.present?

    compute_growth_from_history
  end

  def compute_growth_from_history
    history = @profile.stat_history
    history = history.is_a?(Array) ? history : []
    return nil if history.size < 2

    oldest = history.first&.dig('followers').to_f
    return nil if oldest.zero?

    newest = history.last&.dig('followers').to_f
    months = [history.size - 1, 1].max
    ((newest - oldest) / oldest) / months
  end
end
