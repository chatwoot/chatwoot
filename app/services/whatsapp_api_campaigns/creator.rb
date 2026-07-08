module WhatsappApiCampaigns
  class Creator
    def initialize(account:, user:, params:)
      @account = account
      @user = user
      @params = params
    end

    def perform
      raise Pundit::NotAuthorizedError unless Config.enabled?

      MediaValidator.new(@params[:media_file]).validate! if @params[:media_file].present?
      campaign = nil
      ActiveRecord::Base.transaction do
        campaign = @account.whatsapp_api_campaigns.create!(campaign_attributes)
        attach_media!(campaign)
      end

      ScheduleDueCampaignsJob.perform_later if campaign.scheduled_at <= Time.current && Config.enabled?
      campaign
    end

    private

    def campaign_attributes
      inbox = fetch_inbox
      template = fetch_template(inbox)
      message_body = selected_body(template)

      {
        created_by: @user,
        inbox: inbox,
        whatsapp_api_message_template: template,
        title: permitted[:title].to_s.strip,
        status: :scheduled,
        audience: normalized_audience,
        message_body: message_body,
        template_snapshot: template_snapshot(template, message_body),
        media_snapshot: media_snapshot,
        media_file_pending: @params[:media_file].present?,
        scheduled_at: scheduled_at
      }
    end

    def scheduled_at
      zone = Crm::Timezone::Resolver.new(account: @account).zone
      raise ArgumentError, 'unresolvable_timezone_for_schedule' if zone.nil?

      zone.parse(permitted[:scheduled_at].to_s)
    end

    def fetch_inbox
      inbox = @account.inboxes.find(permitted[:inbox_id])
      return inbox if inbox.api? && inbox.channel.whatsapp_api_campaign_channel?

      raise ArgumentError, 'inbox_not_marked_for_whatsapp_api_campaigns'
    end

    def fetch_template(inbox)
      template_id = permitted[:template_id].presence
      return if template_id.blank?

      @account.whatsapp_api_message_templates.active.for_inbox(inbox.id).find(template_id)
    end

    def selected_body(template)
      body = template&.body.presence || permitted[:message_body].to_s
      unsupported = TemplateRenderer.unsupported_variables_in(body)
      raise ArgumentError, "unsupported_variables: #{unsupported.join(', ')}" if unsupported.present?

      body
    end

    def attach_media!(campaign)
      return if @params[:media_file].blank?

      campaign.media_file.attach(@params[:media_file])
      campaign.update!(media_snapshot: media_snapshot(campaign.media_file.blob))
    end

    def template_snapshot(template, body)
      {
        id: template&.id,
        name: template&.name,
        body: body,
        variables: TemplateRenderer.variables_in(body)
      }.compact
    end

    def media_snapshot(blob = nil)
      return {} if blob.blank?

      {
        filename: blob.filename.to_s,
        content_type: blob.content_type,
        byte_size: blob.byte_size
      }
    end

    def normalized_audience
      audience = Array(permitted[:audience]).map do |entry|
        item = entry.respond_to?(:to_unsafe_h) ? entry.to_unsafe_h : entry.to_h
        { type: item['type'] || item[:type], id: item['id'] || item[:id] }
      end
      audience.select { |entry| entry[:type] == 'Label' && entry[:id].present? }
    end

    def permitted
      @permitted ||= @params.permit(:title, :inbox_id, :template_id, :message_body, :scheduled_at, audience: [:type, :id])
    end
  end
end
