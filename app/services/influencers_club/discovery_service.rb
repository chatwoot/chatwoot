class InfluencersClub::DiscoveryService
  DEFAULT_PAGING = { limit: 5, page: 1 }.freeze

  def initialize(account:, client: InfluencersClub::Client.new)
    @client = client
    @account = account
  end

  def perform(filter_params:, paging: DEFAULT_PAGING)
    filters = build_filters(filter_params)
    @client.post('/public/v1/discovery/', {
                   platform: 'instagram',
                   paging: paging,
                   sort: { sort_by: 'relevancy', sort_order: 'desc' },
                   filters: filters
                 })
  end

  private

  def build_filters(params)
    filters = {}
    filters[:ai_search] = params[:ai_search] if params[:ai_search].present?
    filters[:number_of_followers] = range_filter(params[:followers]) if params[:followers].present?
    filters[:location] = Array(params[:location]).compact_blank if params[:location].present?
    if params[:engagement_percent_min].present? || params[:engagement_percent_max].present?
      er_range = {}
      er_range[:min] = params[:engagement_percent_min].to_f if params[:engagement_percent_min].present?
      er_range[:max] = params[:engagement_percent_max].to_f if params[:engagement_percent_max].present?
      filters[:engagement_percent] = er_range
    end
    filters[:profile_language] = Array(params[:profile_language]).compact_blank if params[:profile_language].present?
    filters[:gender] = params[:gender] if params[:gender].present?
    filters[:hashtags] = Array(params[:hashtags]).compact_blank if params[:hashtags].present?
    filters[:keywords_in_bio] = Array(params[:keywords_in_bio]).compact_blank if params[:keywords_in_bio].present?
    filters[:average_views_for_reels] = { min: params[:avg_reels_min].to_f } if params[:avg_reels_min].present?
    filters[:follower_growth] = { growth_percentage: params[:growth_min].to_f, time_range_months: 3 } if params[:growth_min].present?
    filters[:reels_percent] = { min: params[:reels_percent_min].to_f } if params[:reels_percent_min].present?
    filters
  end

  def range_filter(range)
    { min: range[:min].to_i, max: range[:max].to_i }.compact_blank
  end
end
