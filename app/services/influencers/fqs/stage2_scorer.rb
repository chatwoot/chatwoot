class Influencers::Fqs::Stage2Scorer
  EUROPE_COUNTRY_CODES = %w[
    AD AL AM AT AZ BA BE BG BY CH CY CZ DE DK EE ES FI FR GB GE GR
    HR HU IE IS IT LI LT LU LV MC MD ME MK MT NL NO PL PT RO RS RU
    SE SI SK SM TR UA VA XK
  ].freeze
  TARGET_INTEREST_IDS = [1560, 36, 11, 1708, 291, 190, 43].freeze
  INTEREST_WEIGHT_THRESHOLD = 0.30
  SUSPICIOUS_TYPE_CODES = %w[mass_followers suspicious].freeze
  FLOOR = 0.1

  def initialize(profile, target_market:)
    @profile = profile
    @target_market = target_market.to_s.upcase
  end

  def score
    aq = audience_quality_factor
    af = audience_fit_factor

    breakdown = {
      audience_quality_factor: aq,
      audience_fit_factor: af,
      audience_credibility: @profile.audience_credibility.to_f,
      eu_audience_ratio: eu_audience_ratio,
      interest_match_ratio: interest_match_ratio
    }

    { aq_factor: aq, af_factor: af, breakdown: breakdown }
  end

  private

  def audience_quality_factor
    credibility = @profile.audience_credibility.to_f
    real_ratio = real_audience_ratio

    raw = (0.6 * credibility) + (0.4 * real_ratio)
    [raw, FLOOR].max
  end

  def real_audience_ratio
    types = extract_audience_types
    return 0.5 if types.empty?

    suspicious_weight = types
                        .select { |t| SUSPICIOUS_TYPE_CODES.include?(t['code']) || t['name'].to_s.downcase.match?(/mass|suspicious/) }
                        .sum { |t| t['weight'].to_f }

    [1.0 - suspicious_weight, 0.0].max
  end

  def audience_fit_factor
    eu_ratio = eu_audience_ratio
    interest_ratio = interest_match_ratio

    raw = (0.7 * eu_ratio) + (0.3 * [interest_ratio, 1.0].min)
    [raw, FLOOR].max
  end

  def eu_audience_ratio
    @eu_audience_ratio ||= begin
      countries = extract_audience_geo
      return 0.0 if countries.empty? # rubocop:disable Lint/NoReturnInBeginEndBlocks

      countries
        .select { |c| EUROPE_COUNTRY_CODES.include?(c['code'].to_s.upcase) }
        .sum { |c| c['weight'].to_f }
    end
  end

  def interest_match_ratio
    @interest_match_ratio ||= begin
      interests = extract_audience_interests
      return 0.0 if interests.empty? # rubocop:disable Lint/NoReturnInBeginEndBlocks

      matched = TARGET_INTEREST_IDS.count do |interest_id|
        interest_pct_for(interests, interest_id) >= INTEREST_WEIGHT_THRESHOLD
      end

      matched.to_f / TARGET_INTEREST_IDS.size
    end
  end

  def extract_audience_types
    types = @profile.audience_types
    return types if types.is_a?(Array) && types.present?

    report_data = @profile.raw_report_data || {}
    fallback = report_data.dig('audience_likers', 'data', 'audience_types') || []
    fallback.is_a?(Array) ? fallback : []
  end

  def extract_audience_geo # rubocop:disable Metrics/CyclomaticComplexity
    geo = @profile.audience_geo
    countries = geo.is_a?(Hash) ? (geo['countries'] || []) : []
    return countries if countries.is_a?(Array) && countries.present?

    report_data = @profile.raw_report_data || {}
    fallback = report_data.dig('audience_likers', 'data', 'audience_geo', 'countries') || []
    fallback.is_a?(Array) ? fallback : []
  end

  def extract_audience_interests
    interests = @profile.audience_interests
    return interests if interests.is_a?(Array)

    report_data = @profile.raw_report_data || {}
    data = report_data.dig('result', 'instagram', 'audience', 'audience_likers', 'data', 'audience_interests') ||
           report_data.dig('result', 'instagram', 'audience', 'audience_followers', 'data', 'audience_interests') || []
    data.is_a?(Array) ? data : []
  end

  def interest_pct_for(interests, interest_id)
    item = interests.find { |interest| (interest['id'] || interest[:id]).to_i == interest_id }
    (item&.dig('weight') || item&.dig(:weight) || 0).to_f
  end
end
