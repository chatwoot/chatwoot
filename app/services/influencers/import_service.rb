class Influencers::ImportService
  def initialize(account:, search_result:, target_market: nil)
    @account = account
    @search_result = search_result
    @target_market = target_market
  end

  def perform
    attrs = InfluencersClub::ResponseParser.parse_discovery_result(@search_result)
    return nil if attrs.blank? || attrs[:username].blank?

    profile = ActiveRecord::Base.transaction do
      contact = find_or_create_contact(attrs)
      profile = create_or_update_profile(contact, attrs)
      run_stage1_scoring(profile)
      profile
    end

    Avatar::AvatarFromUrlJob.perform_later(profile.contact, attrs[:profile_picture_url]) if attrs[:profile_picture_url].present?

    profile
  end

  private

  def find_or_create_contact(attrs)
    identifier = "ig:#{attrs[:username]}"
    contact = @account.contacts.find_by(identifier: identifier)
    return contact if contact.present?

    @account.contacts.create!(
      identifier: identifier,
      name: attrs[:fullname] || attrs[:username],
      contact_type: :lead,
      custom_attributes: build_custom_attributes(attrs)
    )
  end

  def create_or_update_profile(contact, attrs)
    profile = contact.influencer_profile || contact.build_influencer_profile(account: @account)

    # Don't overwrite enriched profiles with less complete discovery data
    if profile.persisted? && profile.report_fetched_at.present?
      profile.update!(target_market: @target_market) if @target_market.present?
      return profile
    end

    profile_attrs = attrs.merge(
      search_engagement_rate: attrs[:engagement_rate],
      target_market: @target_market,
      last_synced_at: Time.current
    )
    profile.assign_attributes(profile_attrs)
    profile.save!
    profile
  end

  def run_stage1_scoring(profile)
    result = Influencers::FqsCalculator.new(profile).perform
    profile.reload
    result
  end

  def build_custom_attributes(attrs)
    {
      'followers_count' => attrs[:followers_count],
      'engagement_rate' => attrs[:engagement_rate],
      'avg_reel_views' => attrs[:avg_reel_views],
      'platform' => 'instagram',
      'instagram_username' => attrs[:username]
    }.compact
  end
end
