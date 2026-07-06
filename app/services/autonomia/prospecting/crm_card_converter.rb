class Autonomia::Prospecting::CrmCardConverter
  Result = Struct.new(:lead, :card, :created, keyword_init: true)

  class Error < StandardError; end

  def initialize(lead:, user:, pipeline_id:, stage_id:)
    @lead = lead
    @account = lead.account
    @user = user
    @pipeline_id = pipeline_id
    @stage_id = stage_id
  end

  def perform
    return Result.new(lead: @lead, card: @lead.crm_card, created: false) if @lead.crm_card.present?

    raise Error, 'CRM is disabled' unless ::Crm::Config.enabled?

    pipeline = @account.crm_pipelines.active.find(@pipeline_id)
    stage = @account.crm_pipeline_stages.where(pipeline: pipeline).find(@stage_id)

    result = ActiveRecord::Base.transaction do
      contact = ensure_contact
      card = create_card(pipeline: pipeline, stage: stage, contact: contact)
      @lead.update!(crm_card: card)

      Result.new(lead: @lead.reload, card: card.reload, created: true)
    end

    ::Crm::Cards::Broadcaster.broadcast(result.card, ::Events::Types::CRM_CARD_CREATED)
    result
  end

  private

  def ensure_contact
    Autonomia::Prospecting::ContactConverter.new(lead: @lead, user: @user).perform.contact
  end

  def create_card(pipeline:, stage:, contact:)
    ::Crm::Cards::Creator.new(
      account: @account,
      user: @user,
      params: card_params(pipeline: pipeline, stage: stage, contact: contact)
    ).perform
  end

  def card_params(pipeline:, stage:, contact:)
    {
      pipeline_id: pipeline.id,
      stage_id: stage.id,
      contact_id: contact&.id,
      title: @lead.name,
      description: description,
      source: 'autonomia_prospecting',
      external_id: "autonomia_prospecting_lead:#{@lead.id}",
      metadata: metadata
    }
  end

  def description
    [
      @lead.category,
      @lead.website,
      [@lead.address, @lead.city, @lead.state, @lead.country].compact_blank.join(', ')
    ].compact_blank.join("\n")
  end

  def metadata
    {
      'autonomia_prospecting' => {
        'lead_id' => @lead.id,
        'provider' => @lead.provider,
        'provider_place_id' => @lead.provider_place_id,
        'rating' => @lead.rating&.to_f,
        'reviews_count' => @lead.reviews_count,
        'source' => 'autonomia_prospecting'
      }
    }
  end
end
