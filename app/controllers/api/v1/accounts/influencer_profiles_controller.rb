# rubocop:disable Metrics/ClassLength
class Api::V1::Accounts::InfluencerProfilesController < Api::V1::Accounts::BaseController
  RESULTS_PER_PAGE = 25
  IMAGE_CACHE_DIR = Rails.root.join('tmp/influencer_images')

  skip_before_action :authenticate_user!, only: [:proxy_image]
  skip_before_action :current_account, only: [:proxy_image]
  before_action :set_profile, only: %i[show request_report approve reject recalculate retry_apify]
  rescue_from InfluencersClub::Client::ApiError, with: :handle_api_error

  def index
    profiles = Current.account.influencer_profiles.includes(contact: { avatar_attachment: :blob })
    profiles = apply_filters(profiles)
    profiles = profiles.order(fqs_score: :desc, created_at: :desc)

    paginated = profiles.page(params[:page] || 1).per(RESULTS_PER_PAGE)

    render json: {
      payload: paginated.map { |p| profile_json(p) },
      meta: {
        count: profiles.count,
        current_page: paginated.current_page,
        has_more: !paginated.last_page?,
        per_status_counts: per_status_counts
      }
    }
  end

  def show
    render json: { payload: profile_json(@profile) }
  end

  def search
    result = Influencers::SearchRegistry::FetchPageService.new(
      account: Current.account,
      filter_params: search_filters,
      page: current_search_page
    ).perform

    render json: {
      payload: result[:profiles].map { |p| profile_json(p) },
      meta: result[:meta]
    }
  end

  def import
    profile = Influencers::ImportService.new(
      account: Current.account,
      search_result: params[:search_result].to_unsafe_h,
      target_market: params[:target_market]
    ).perform

    if profile
      render json: { payload: profile_json(profile) }, status: :ok
    else
      render json: { error: 'Could not import profile' }, status: :unprocessable_entity
    end
  end

  def bulk_import
    profiles = params[:search_results].filter_map do |result|
      Influencers::ImportService.new(
        account: Current.account,
        search_result: result.to_unsafe_h,
        target_market: params[:target_market]
      ).perform
    end

    render json: { payload: profiles.map { |p| profile_json(p) }, meta: { imported: profiles.size } }
  end

  def request_report
    @profile.update!(enrichment_pending: true)
    Influencers::FetchReportJob.perform_later(@profile.id)
    render json: { payload: profile_json(@profile.reload) }
  end

  def bulk_request_report
    profile_ids = params[:profile_ids]
    profiles = Current.account.influencer_profiles.where(id: profile_ids)

    profiles.where(status: :discovered).update_all(enrichment_pending: true) # rubocop:disable Rails/SkipsModelValidations
    Influencers::BulkFetchReportsJob.perform_later(profile_ids)

    render json: { message: "Queued #{profile_ids.size} report(s)" }
  end

  def approve
    profile = Influencers::ApproveService.new(profile: @profile, user: Current.user).perform
    render json: { payload: profile_json(profile) }
  end

  def reject
    reason = params[:reason]
    return render json: { error: 'Rejection reason is required' }, status: :unprocessable_entity if reason.blank?

    profile = Influencers::RejectService.new(profile: @profile, reason: reason).perform
    render json: { payload: profile_json(profile) }
  end

  def recalculate
    Influencers::ScoreProfileJob.perform_later(@profile.id, auto_decide: false)
    render json: { message: 'Recalculation queued' }
  end

  def retry_apify
    return render json: { error: 'Profile is not in failed state' }, status: :unprocessable_entity unless @profile.apify_apify_failed?

    Influencers::ApifyEnrichJob.perform_later(@profile.id)
    @profile.update!(apify_status: :apify_pending, apify_error: nil)
    render json: { payload: profile_json(@profile.reload) }
  end

  ALLOWED_IMAGE_HOSTS = /\A[a-z0-9-]+\.(cdninstagram|fbcdn)\.com\z/i

  def proxy_image
    url = params[:url]
    uri = URI.parse(url)
    return head :bad_request unless uri.is_a?(URI::HTTPS) && uri.host.match?(ALLOWED_IMAGE_HOSTS)

    cache_key = Digest::SHA256.hexdigest(url)
    cache_path = IMAGE_CACHE_DIR.join("#{cache_key}.jpg")

    if File.exist?(cache_path)
      expires_in 7.days, public: true
      return send_file cache_path, type: 'image/jpeg', disposition: 'inline'
    end

    response = Net::HTTP.get_response(uri)
    return head :bad_gateway unless response.is_a?(Net::HTTPSuccess)

    FileUtils.mkdir_p(IMAGE_CACHE_DIR)
    File.binwrite(cache_path, response.body)

    expires_in 7.days, public: true
    send_data response.body, type: response['content-type'], disposition: 'inline', status: :ok
  rescue URI::InvalidURIError
    head :bad_request
  end

  private

  def set_profile
    @profile = Current.account.influencer_profiles.find(params[:id])
  end

  def apply_filters(profiles)
    profiles = profiles.where(status: params[:status]) if params[:status].present?
    profiles = profiles.where('fqs_score >= ?', params[:min_fqs]) if params[:min_fqs].present?
    profiles = profiles.where('fqs_score <= ?', params[:max_fqs]) if params[:max_fqs].present?
    profiles = profiles.where(target_market: params[:target_market]) if params[:target_market].present?
    profiles
  end

  def per_status_counts
    Current.account.influencer_profiles.group(:status).count
  end

  def search_params
    params.permit(
      :page,
      :ai_search, :gender, :engagement_percent_min, :engagement_percent_max,
      :avg_reels_min, :growth_min, :reels_percent_min,
      followers: %i[min max],
      location: [],
      profile_language: [],
      hashtags: [],
      keywords_in_bio: []
    ).to_h.deep_symbolize_keys
  end

  def search_filters
    search_params.except(:page)
  end

  def current_search_page
    search_params[:page].presence || 1
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def extract_recent_posts(profile)
    # Use persistent column first, fall back to raw_report_data
    return profile.recent_posts if profile.recent_posts.present?

    post_data = profile.raw_report_data&.dig('result', 'instagram', 'post_data')
    return [] if post_data.blank?

    reel_types = %w[clips reel].freeze
    post_data
      .reject { |p| reel_types.any? { |t| p['product_type']&.include?(t) } }
      .first(6)
      .map do |post|
        engagement = post['engagement'] || {}
        media = Array(post['media']).first || {}
        {
          url: post['post_url'],
          thumbnail_url: media['url'],
          type: post['product_type'],
          likes: engagement['likes'],
          comments: engagement['comments'],
          timestamp: post['created_at']
        }
      end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def niche_details(profile)
    return nil unless profile.report_available?

    Influencers::Fqs::NicheMatcher.new(profile).details
  rescue StandardError
    nil
  end

  def handle_api_error(exception)
    message = if exception.message.include?('credits')
                'No credits remaining. Please refill your influencers.club account.'
              elsif exception.code == 429
                'Rate limit exceeded. Please wait a moment and try again.'
              else
                "influencers.club API error: #{exception.message}"
              end

    render json: { error: message }, status: :unprocessable_entity
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def profile_json(profile)
    {
      id: profile.id,
      username: profile.username,
      fullname: profile.fullname,
      platform: profile.platform,
      profile_url: profile.profile_url,
      profile_picture_url: profile.profile_picture_url,
      avatar_url: profile.contact&.avatar_url.presence,
      bio: profile.bio,
      is_verified: profile.is_verified,
      followers_count: profile.followers_count,
      following_count: profile.following_count,
      engagement_rate: profile.engagement_rate,
      effective_er: profile.effective_er,
      hidden_like_posts_rate: profile.hidden_like_posts_rate,
      search_engagement_rate: profile.search_engagement_rate,
      avg_reel_views: profile.avg_reel_views,
      median_reel_views: profile.median_reel_views,
      avg_likes: profile.avg_likes,
      avg_comments: profile.avg_comments,
      fqs_score: profile.fqs_score,
      fqs_stage1_score: profile.fqs_stage1_score,
      fqs_stage2_score: profile.fqs_stage2_score,
      fqs_breakdown: profile.fqs_breakdown,
      fqs_hard_filter_results: profile.fqs_hard_filter_results,
      audience_credibility: profile.audience_credibility,
      audience_types: profile.audience_types,
      audience_geo: profile.audience_geo,
      audience_interests: profile.audience_interests,
      interests: profile.interests,
      top_hashtags: profile.top_hashtags,
      niche_details: niche_details(profile),
      recent_reels: profile.recent_reels,
      recent_posts: extract_recent_posts(profile),
      status: profile.status,
      rejection_reason: profile.rejection_reason,
      target_market: profile.target_market,
      report_fetched_at: profile.report_fetched_at,
      apify_status: profile.apify_status,
      apify_error: profile.apify_error,
      apify_enriched_at: profile.apify_enriched_at,
      enrichment_pending: profile.enrichment_pending,
      contact_id: profile.contact_id,
      created_at: profile.created_at,
      updated_at: profile.updated_at
    }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
# rubocop:enable Metrics/ClassLength
