class Autonomia::Prospecting::CampaignSegmentBuilder
  Result = Struct.new(:list, :label, :campaign, :eligible_leads, :blocked_leads, :created_contacts_count, keyword_init: true)

  Error = Class.new(StandardError)

  ELIGIBLE_STATUS = 'ready_for_campaign'.freeze

  def initialize(list:, user:, campaign_id: nil, segment_name: nil)
    @list = list
    @account = list.account
    @user = user
    @campaign_id = campaign_id.presence
    @segment_name = segment_name.presence || list.name
  end

  def perform
    raise Error, 'prospecting.campaign.empty_list' if leads.empty?
    raise Error, 'prospecting.campaign.no_eligible_leads' if eligible_leads.empty?

    created_contacts_count = 0
    label = nil
    campaign = nil

    with_suppressed_contact_events do
      ActiveRecord::Base.transaction do
        label = ensure_label!
        eligible_leads.each do |lead|
          result = ensure_contact!(lead)
          created_contacts_count += 1 if result.created
          apply_label!(result.contact, label)
        end

        campaign = attach_to_campaign!(label) if @campaign_id.present?
        persist_segment_metadata!(label, campaign)
      end
    end

    Result.new(
      list: @list.reload,
      label: label.reload,
      campaign: campaign&.reload,
      eligible_leads: eligible_leads,
      blocked_leads: blocked_leads,
      created_contacts_count: created_contacts_count
    )
  end

  private

  def leads
    @leads ||= @list.leads.order(:id).to_a
  end

  def eligible_leads
    @eligible_leads ||= leads.select { |lead| eligible?(lead) }
  end

  def blocked_leads
    @blocked_leads ||= leads.reject { |lead| eligible?(lead) }
  end

  def eligible?(lead)
    lead.status == ELIGIBLE_STATUS && whatsapp_verified?(lead)
  end

  def whatsapp_verified?(lead)
    lead.metadata.to_h.dig('whatsapp_verification', 'status') == 'verified'
  end

  def ensure_label!
    label = @account.labels.find_or_initialize_by(title: label_title)
    raise Error, 'prospecting.campaign.label_collision_visible_on_sidebar' if label.persisted? && label.show_on_sidebar?

    label.assign_attributes(
      description: "Segmento gerado pela prospeccao: #{@list.name}",
      show_on_sidebar: false
    )
    label.save!
    label
  end

  def label_title
    @label_title ||= begin
      slug = ActiveSupport::Inflector.transliterate(@segment_name.to_s)
                                     .downcase
                                     .gsub(/[^a-z0-9_-]+/, '_')
                                     .gsub(/\A_+|_+\z/, '')
                                     .presence || 'lista'
      "prospeccao_#{@list.id}_#{slug}"[0, 120]
    end
  end

  def ensure_contact!(lead)
    Autonomia::Prospecting::ContactConverter.new(lead: lead, user: @user).perform
  end

  def apply_label!(contact, label)
    contact.label_list.add(label.title)
    contact.save!
  end

  def attach_to_campaign!(label)
    campaign = @account.campaigns.find_by!(display_id: @campaign_id)
    raise Error, 'prospecting.campaign.unsupported_campaign' unless campaign.one_off?
    raise Error, 'prospecting.campaign.campaign_not_active' unless campaign.active?

    audience = Array(campaign.audience).map { |item| item.to_h.stringify_keys }
    label_audience = { 'type' => 'Label', 'id' => label.id }
    audience << label_audience unless audience.any? { |item| item['type'] == 'Label' && item['id'].to_i == label.id }
    campaign.update!(audience: audience)
    campaign
  end

  def persist_segment_metadata!(label, campaign)
    metadata = @list.metadata.to_h
    metadata['campaign_segment'] = {
      'label_id' => label.id,
      'label_title' => label.title,
      'campaign_id' => campaign&.display_id,
      'campaign_title' => campaign&.title,
      'eligible_count' => eligible_leads.size,
      'blocked_count' => blocked_leads.size,
      'generated_by_id' => @user&.id,
      'generated_at' => Time.current.iso8601
    }.compact
    @list.update!(metadata: metadata)
  end

  def with_suppressed_contact_events
    previous = Current.suppress_contact_events
    Current.suppress_contact_events = true
    yield
  ensure
    Current.suppress_contact_events = previous
  end
end
