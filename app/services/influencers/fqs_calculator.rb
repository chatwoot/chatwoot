class Influencers::FqsCalculator
  EUROPE_COUNTRY_CODES = %w[
    AD AL AM AT AZ BA BE BG BY CH CY CZ DE DK EE ES FI FR GB GE GR
    HR HU IE IS IT LI LT LU LV MC MD ME MK MT NL NO PL PT RO RS RU
    SE SI SK SM TR UA VA XK
  ].freeze

  GEO_BASELINE = 0.8 # 80% EU audience = factor 1.0
  AF_BASELINE = 5.0  # sum(weight×affinity) of 5.0 = factor 1.0
  AF_TARGET_INTERESTS = ['Home Decor, Furniture & Garden', 'Camera & Photography'].freeze
  FACTOR_FLOOR = 0.1

  def initialize(profile)
    @profile = profile
  end

  def perform
    return skip_discovery unless @profile.report_available?

    backfill_median_reel_views

    er = er_factor
    views = views_factor
    geo = geo_factor
    aq = aq_factor
    af = af_factor
    engagement = Math.sqrt(er * views)
    score = (engagement * geo * aq * af * 100).round(1)

    warnings = Influencers::Fqs::HardFilter.new(@profile).warnings

    breakdown = {
      engagement_factor: engagement.round(4),
      er_factor: er.round(4),
      views_factor: views.round(4),
      geo_factor: geo.round(4),
      aq_factor: aq.round(4),
      af_factor: af.round(4),
      engagement_rate: @profile.engagement_rate.to_f,
      median_reel_views: (@profile.median_reel_views || @profile.avg_reel_views).to_f,
      followers_count: @profile.followers_count,
      eu_audience_ratio: eu_audience_ratio.round(4),
      audience_credibility: @profile.audience_credibility.to_f.round(4),
      af_score: af_raw_score.round(4)
    }

    @profile.update!(
      fqs_score: score,
      fqs_breakdown: breakdown,
      fqs_stage1_score: nil,
      fqs_stage2_score: nil,
      fqs_hard_filter_results: { warnings: warnings }
    )

    { score: score, breakdown: breakdown, warnings: warnings }
  end

  private

  # No FQS for non-enriched profiles
  def skip_discovery
    @profile.update!(fqs_score: nil, fqs_breakdown: nil, fqs_hard_filter_results: nil)
    nil
  end

  # ER factor: piecewise linear
  # 0% → 0, 2% → 1.0, 5% → 2.0, 10% → 3.0, >10% capped
  def er_factor
    er = @profile.engagement_rate.to_f
    return 0.0 if er <= 0

    if er <= 0.02
      er / 0.02
    elsif er <= 0.05
      1.0 + ((er - 0.02) / 0.03)
    elsif er <= 0.10
      2.0 + ((er - 0.05) / 0.05)
    else
      3.0
    end
  end

  # Views factor: median_reel_views / followers (direct ratio)
  # Neutral (1.0) when no reel data available
  def views_factor
    followers = @profile.followers_count.to_f
    views = @profile.median_reel_views.to_f.nonzero? || @profile.avg_reel_views.to_f
    return 1.0 if followers.zero? || views.zero?

    views / followers
  end

  # Geo factor: eu_audience_ratio / 0.8, capped at 1.0, floor 0.1
  def geo_factor
    ratio = eu_audience_ratio
    return FACTOR_FLOOR if ratio.zero?

    [[ratio / GEO_BASELINE, 1.0].min, FACTOR_FLOOR].max
  end

  # Audience Quality factor: audience_credibility (0-1), floor 0.1
  def aq_factor
    credibility = @profile.audience_credibility.to_f
    credibility = 0.5 if credibility.zero? # fallback when missing
    [credibility, FACTOR_FLOOR].max
  end

  # Audience Fit factor: sum(weight × affinity) for target interests, normalized by 5.0
  def af_factor
    [af_raw_score / AF_BASELINE, FACTOR_FLOOR].max
  end

  def af_raw_score
    @af_raw_score ||= begin
      interests = @profile.audience_interests
      return 0.0 unless interests.is_a?(Array)

      AF_TARGET_INTERESTS.sum do |name|
        i = interests.find { |x| x['name'] == name }
        i ? i['weight'].to_f * i['affinity'].to_f : 0.0
      end
    end
  end

  def eu_audience_ratio
    @eu_audience_ratio ||= begin
      countries = extract_audience_geo
      return 0.0 if countries.empty?

      countries
        .select { |c| EUROPE_COUNTRY_CODES.include?(c['code'].to_s.upcase) }
        .sum { |c| c['weight'].to_f }
    end
  end

  def extract_audience_geo
    geo = @profile.audience_geo
    countries = geo.is_a?(Hash) ? (geo['countries'] || []) : []
    return countries if countries.is_a?(Array) && countries.present?

    report_data = @profile.raw_report_data || {}
    fallback = report_data.dig('result', 'instagram', 'audience', 'audience_likers', 'data', 'audience_geo', 'countries') ||
               report_data.dig('result', 'instagram', 'audience', 'audience_followers', 'data', 'audience_geo', 'countries') || []
    fallback.is_a?(Array) ? fallback : []
  end

  def backfill_median_reel_views
    median = (@profile.raw_report_data || {}).dig('result', 'instagram', 'reels', 'median_view_count')
    @profile.update!(median_reel_views: median) if median.present? && median != @profile.median_reel_views
  end
end
