class Influencers::ApproveService
  INFLUENCER_LABEL = 'influencer'.freeze

  def initialize(profile:, user: nil)
    @profile = profile
    @user = user
  end

  def perform
    ActiveRecord::Base.transaction do
      @profile.transition_to!(:accepted)
      @profile.update!(rejection_reason: nil)
      add_influencer_label
      assign_pipeline_stage
      sync_custom_attributes
    end
    @profile
  end

  private

  def add_influencer_label
    contact = @profile.contact
    labels = contact.label_list || []
    return if labels.include?(INFLUENCER_LABEL)

    contact.update!(label_list: labels + [INFLUENCER_LABEL])
  end

  def assign_pipeline_stage
    contact = @profile.contact
    account = @profile.account

    label = account.labels.find_by(title: INFLUENCER_LABEL)
    return unless label

    first_stage = label.pipeline_stages.order(:position).first
    return unless first_stage

    ContactPipelineStage.find_or_create_by!(
      contact: contact,
      pipeline_stage: first_stage
    )
  end

  def sync_custom_attributes
    contact = @profile.contact
    attrs = contact.custom_attributes || {}
    attrs.merge!(
      'followers_count' => @profile.followers_count,
      'engagement_rate' => @profile.engagement_rate,
      'avg_reel_views' => @profile.avg_reel_views,
      'fqs_score' => @profile.fqs_score,
      'audience_credibility' => @profile.audience_credibility,
      'platform' => @profile.platform,
      'instagram_username' => @profile.username
    )
    contact.update!(custom_attributes: attrs.compact)
  end
end
