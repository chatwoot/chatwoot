class Autonomia::Prospecting::LeadScorer
  SIGNAL_KEYS = Autonomia::Prospecting::ScoringProfile::DEFAULT_WEIGHTS.keys.freeze

  def initialize(lead_attributes:, query:, google_rank:, weights:)
    @lead_attributes = lead_attributes.symbolize_keys
    @query = query.to_s.downcase
    @google_rank = google_rank.to_i
    @weights = Autonomia::Prospecting::ScoringProfile::DEFAULT_WEIGHTS
                                                        .merge(weights.to_h.slice(*SIGNAL_KEYS))
                                                        .transform_values(&:to_f)
  end

  def perform
    normalized = normalized_weights
    signals = signal_scores
    score = normalized.sum { |key, weight| signals[key].to_f * weight }.round(2)
    score = [[score, 0].max, 100].min

    {
      score: score,
      priority_score: score,
      score_breakdown: SIGNAL_KEYS.index_with do |key|
        {
          'signal' => signals[key].round(2),
          'weight' => @weights[key].round(2),
          'weighted_score' => (signals[key] * normalized[key]).round(2)
        }
      end,
      negative_factors: negative_factors(signals),
      human_insight: human_insight(score, signals)
    }
  end

  private

  def normalized_weights
    total = @weights.values.sum
    return SIGNAL_KEYS.index_with { 0.0 } if total <= 0

    SIGNAL_KEYS.index_with { |key| @weights[key].to_f / total }
  end

  def signal_scores
    {
      'rating' => rating_score,
      'reviews_count' => reviews_score,
      'website' => presence_score(:website),
      'phone' => presence_score(:phone),
      'google_rank' => rank_score,
      'query_relevance' => query_relevance_score
    }
  end

  def rating_score
    rating = @lead_attributes[:rating].to_f
    return 0.0 if rating <= 0

    (rating / 5.0 * 100).clamp(0, 100)
  end

  def reviews_score
    reviews = @lead_attributes[:reviews_count].to_i
    return 0.0 if reviews <= 0

    [[Math.log10(reviews + 1) / Math.log10(501) * 100, 100].min, 0].max
  end

  def presence_score(attribute)
    @lead_attributes[attribute].present? ? 100.0 : 0.0
  end

  def rank_score
    return 0.0 if @google_rank <= 0

    [[100 - ((@google_rank - 1) * 5), 0].max, 100].min
  end

  def query_relevance_score
    name = @lead_attributes[:name].to_s.downcase
    category = @lead_attributes[:category].to_s.downcase
    query_terms = @query.split(/\s+/).reject { |term| term.length < 3 }
    return 50.0 if query_terms.blank?

    matches = query_terms.count { |term| name.include?(term) || category.include?(term) }
    (matches.to_f / query_terms.size * 100).clamp(0, 100)
  end

  def negative_factors(signals)
    [].tap do |factors|
      factors << 'missing_website' if signals['website'].zero?
      factors << 'missing_phone' if signals['phone'].zero?
      rating = @lead_attributes[:rating].to_f
      factors << 'low_rating' if rating.positive? && rating < 3.5
      factors << 'low_reviews' if @lead_attributes[:reviews_count].to_i < 10
    end
  end

  def human_insight(score, signals)
    return 'Lead prioritário: boa reputação e dados de contato completos.' if score >= 80
    return 'Boa oportunidade, mas vale revisar sinais de contato e reputação.' if score >= 60
    return 'Lead com sinais incompletos; priorize após validação manual.' if signals['website'].zero? || signals['phone'].zero?

    'Lead de baixa prioridade para abordagem inicial.'
  end
end
