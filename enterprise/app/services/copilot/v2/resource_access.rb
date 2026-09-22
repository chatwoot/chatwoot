# Authorization and safe projections for the additional account resources.
module Copilot::V2::ResourceAccess
  private

  def policy_context
    { user: @user, account: @account, account_user: @membership }
  end

  def policy_read!(policy, method = :index?)
    raise Pundit::NotAuthorizedError, 'Resource access denied' unless policy.new(policy_context, nil).public_send(method)
  end

  def resource_gate!(resource) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    case resource
    when 'conversations', 'messages', 'mentions', 'participants'
      permissions = @membership.custom_role&.permissions
      if permissions && !permissions.intersect?(%w[conversation_manage conversation_unassigned_manage conversation_participating_manage])
        raise Pundit::NotAuthorizedError, 'Conversation access denied'
      end
    when 'contacts', 'notes'
      raise Pundit::NotAuthorizedError, 'Contact access denied' unless contacts_allowed?
    when 'custom_attribute_definitions' then policy_read!(CustomAttributeDefinitionPolicy)
    when 'inboxes' then policy_read!(InboxPolicy)
    when 'agents' then policy_read!(UserPolicy)
    when 'teams' then policy_read!(TeamPolicy)
    when 'labels' then policy_read!(LabelPolicy)
    when 'portals' then policy_read!(PortalPolicy)
    when 'articles'
      allowed = @membership.custom_role ? @membership.custom_role.permissions.include?('knowledge_base_manage') : true
      raise Pundit::NotAuthorizedError, 'Knowledge access denied' unless allowed
    when 'documents', 'faqs'
      policy_read!(Captain::AssistantPolicy)
      raise Pundit::NotAuthorizedError, 'Assistant is outside this account' if @assistant && @assistant.account_id != @account.id
    when 'account_settings', 'inbox_settings', 'working_hours'
      raise Pundit::NotAuthorizedError, 'Administrator required' unless @membership.administrator?
    when 'applied_slas' then resource_gate!('conversations')
    when 'sla_policies' then policy_read!(SlaPolicyPolicy)
    when 'campaigns', 'campaign_metrics' then policy_read!(CampaignPolicy)
    when 'reports' then policy_read!(ReportPolicy, :view?)
    end
    raise Pundit::NotAuthorizedError, 'SLA feature disabled' if %w[sla_policies applied_slas].include?(resource) && !@account.feature_enabled?('sla')

    resource_gate!('contacts') if resource == 'shopify_orders'
    resource_gate!('conversations') if resource == 'linear_linked_issues'
    external_hook!(resource.split('_').first) if resource.start_with?('linear_', 'shopify_')
  end

  def additional_scope(resource) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
    case resource
    when 'inboxes'
      @membership.administrator? ? @account.inboxes : @user.inboxes.where(account_id: @account.id)
    when 'custom_attribute_definitions' then @account.custom_attribute_definitions
    when 'agents' then @account.users
    when 'teams' then @account.teams
    when 'labels' then @account.labels
    when 'portals' then @account.portals
    when 'articles' then @account.articles
    when 'documents', 'faqs'
      relation = resource == 'documents' ? @account.captain_documents : Captain::AssistantResponse.where(account_id: @account.id).approved
      @assistant ? relation.where(assistant_id: @assistant.id) : relation
    when 'notifications' then @user.notifications.where(account_id: @account.id, primary_actor_type: 'Conversation')
    when 'account_settings' then Account.where(id: @account.id)
    when 'inbox_settings' then @account.inboxes
    when 'working_hours' then WorkingHour.where(inbox_id: @account.inboxes.select(:id))
    when 'sla_policies' then @account.sla_policies
    when 'applied_slas'
      @account.applied_slas.with_sla_applicable_conversation.where(conversation_id: scope('conversations').select(:id))
    when 'campaigns' then @account.campaigns
    end
  end

  def knowledge_projection(record, row)
    case record
    when Captain::AssistantResponse
      row['parts'] = [{ 'id' => "faq:#{record.id}:answer", 'text' => "#{record.question}\n#{record.answer}", 'provenance' => 'approved_faq' }]
      row['limitations'] = ['derived_faq_not_full_source']
    when Captain::Document
      row['parts'] = if record.content.present?
                       [{ 'id' => "document:#{record.id}:content", 'text' => record.content,
                          'provenance' => 'stored_document_content' }]
                     else
                       []
                     end
      row['limitations'] = record.content.present? ? ['stored_source_only_no_attachment_extraction'] : ['source_text_unavailable']
    when Article
      row['parts'] = [{ 'id' => "article:#{record.id}:content", 'text' => record.content.to_s, 'provenance' => 'article_content' }]
    when AppliedSla
      row['deadlines'] = record.due_at_values.as_json
    end
    row
  end

  def external_hook!(app_id)
    hook = @account.hooks.find_by(app_id: app_id)
    raise Pundit::NotAuthorizedError, 'Integration unavailable' unless hook&.enabled? && hook.feature_allowed?

    hook
  end
end
