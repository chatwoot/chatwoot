class AccountRestoreService
  def initialize(account, backup_data)
    @account = account
    @backup_data = backup_data
    @user_mapping = {}
    @contact_mapping = {}
    @inbox_mapping = {}
    @team_mapping = {}
  end

  def restore_backup
    ActiveRecord::Base.transaction do
      clear_existing_data
      restore_account_data
      restore_related_data
    end

    {
      success: true,
      message: 'Backup restaurado com sucesso'
    }
  rescue StandardError => e
    {
      success: false,
      message: "Erro ao restaurar backup: #{e.message}"
    }
  end

  private

  def clear_existing_data
    # Remove todos os dados relacionados à conta, mantendo apenas a estrutura básica
    @account.contacts.destroy_all
    @account.conversations.destroy_all
    @account.messages.destroy_all
    @account.inboxes.destroy_all
    @account.teams.destroy_all
    @account.labels.destroy_all
    @account.canned_responses.destroy_all
    @account.automation_rules.destroy_all
    @account.macros.destroy_all
    @account.custom_attribute_definitions.destroy_all
    @account.webhooks.destroy_all
    @account.notes.destroy_all
    @account.campaigns.destroy_all
    @account.agent_bots.destroy_all
    @account.working_hours.destroy_all
    @account.notification_settings.destroy_all
    @account.custom_filters.destroy_all
    @account.portals.destroy_all
    @account.articles.destroy_all
    @account.categories.destroy_all
  end

  def restore_account_data
    account_data = @backup_data['account_data']
    
    # Atualiza dados da conta
    @account.update!(
      name: account_data['name'],
      domain: account_data['domain'],
      support_email: account_data['support_email'],
      settings: account_data['settings'],
      custom_attributes: account_data['custom_attributes'],
      locale: account_data['locale'],
      feature_flags: account_data['feature_flags'],
      limits: account_data['limits']
    )

    # Restaura usuários da conta (account_users)
    restore_account_users(account_data['account_users'])
  end

  def restore_account_users(account_users_data)
    return unless account_users_data

    account_users_data.each do |au_data|
      user_data = au_data['user']
      
      # Encontra ou cria usuário
      user = User.find_by(email: user_data['email']) || 
             User.create!(
               name: user_data['name'],
               email: user_data['email'],
               display_name: user_data['display_name'],
               provider: user_data['provider'] || 'email',
               uid: user_data['uid'] || user_data['email'],
               custom_attributes: user_data['custom_attributes'],
               password: SecureRandom.hex(10),
               confirmed_at: Time.current
             )

      @user_mapping[au_data['user_id']] = user.id

      # Cria ou atualiza account_user
      account_user = @account.account_users.find_or_create_by(user: user) do |au|
        au.role = au_data['role']
        au.availability = au_data['availability']
      end
    end
  end

  def restore_related_data
    related_data = @backup_data['related_data']
    
    restore_teams(related_data['teams'])
    restore_labels(related_data['labels'])
    restore_custom_attributes(related_data['custom_attribute_definitions'])
    restore_canned_responses(related_data['canned_responses'])
    restore_automation_rules(related_data['automation_rules'])
    restore_macros(related_data['macros'])
    restore_webhooks(related_data['webhooks'])
    restore_working_hours(related_data['working_hours'])
    restore_custom_filters(related_data['custom_filters'])
    restore_agent_bots(related_data['agent_bots'])
    restore_campaigns(related_data['campaigns'])
    restore_inboxes(related_data['inboxes'])
    restore_contacts(related_data['contacts'])
    restore_conversations(related_data['conversations'])
    restore_messages(related_data['messages'])
    restore_notes(related_data['notes'])
    restore_notification_settings(related_data['notification_settings'])
    restore_portals(related_data['portals'])
    restore_categories(related_data['categories'])
    restore_articles(related_data['articles'])
  end

  def restore_teams(teams_data)
    return unless teams_data

    teams_data.each do |team_data|
      team = @account.teams.create!(
        name: team_data['name'],
        description: team_data['description'],
        allow_auto_assign: team_data['allow_auto_assign']
      )
      
      @team_mapping[team_data['id']] = team.id

      # Restaura membros do time
      team_data['team_members']&.each do |tm_data|
        next unless @user_mapping[tm_data['user_id']]

        team.team_members.create!(
          user_id: @user_mapping[tm_data['user_id']]
        )
      end
    end
  end

  def restore_labels(labels_data)
    return unless labels_data

    labels_data.each do |label_data|
      @account.labels.create!(
        title: label_data['title'],
        description: label_data['description'],
        color: label_data['color'],
        show_on_sidebar: label_data['show_on_sidebar']
      )
    end
  end

  def restore_custom_attributes(attributes_data)
    return unless attributes_data

    attributes_data.each do |attr_data|
      @account.custom_attribute_definitions.create!(
        attribute_display_name: attr_data['attribute_display_name'],
        attribute_key: attr_data['attribute_key'],
        attribute_display_type: attr_data['attribute_display_type'],
        default_value: attr_data['default_value'],
        attribute_model: attr_data['attribute_model'],
        attribute_values: attr_data['attribute_values']
      )
    end
  end

  def restore_canned_responses(responses_data)
    return unless responses_data

    responses_data.each do |response_data|
      @account.canned_responses.create!(
        short_code: response_data['short_code'],
        content: response_data['content']
      )
    end
  end

  def restore_automation_rules(rules_data)
    return unless rules_data

    rules_data.each do |rule_data|
      @account.automation_rules.create!(
        name: rule_data['name'],
        description: rule_data['description'],
        event_name: rule_data['event_name'],
        conditions: rule_data['conditions'],
        actions: rule_data['actions'],
        active: rule_data['active']
      )
    end
  end

  def restore_macros(macros_data)
    return unless macros_data

    macros_data.each do |macro_data|
      @account.macros.create!(
        name: macro_data['name'],
        visibility: macro_data['visibility'],
        actions: macro_data['actions'],
        created_by_id: @user_mapping[macro_data['created_by_id']] || @account.users.first&.id
      )
    end
  end

  def restore_webhooks(webhooks_data)
    return unless webhooks_data

    webhooks_data.each do |webhook_data|
      @account.webhooks.create!(
        url: webhook_data['url'],
        webhook_type: webhook_data['webhook_type'],
        subscriptions: webhook_data['subscriptions']
      )
    end
  end

  def restore_working_hours(working_hours_data)
    return unless working_hours_data

    working_hours_data.each do |wh_data|
      @account.working_hours.create!(
        inbox_id: @inbox_mapping[wh_data['inbox_id']],
        day_of_week: wh_data['day_of_week'],
        open_hour: wh_data['open_hour'],
        open_minutes: wh_data['open_minutes'],
        close_hour: wh_data['close_hour'],
        close_minutes: wh_data['close_minutes'],
        closed_all_day: wh_data['closed_all_day']
      )
    end
  end

  def restore_custom_filters(filters_data)
    return unless filters_data

    filters_data.each do |filter_data|
      @account.custom_filters.create!(
        name: filter_data['name'],
        filter_type: filter_data['filter_type'],
        query: filter_data['query'],
        user_id: @user_mapping[filter_data['user_id']] || @account.users.first&.id
      )
    end
  end

  def restore_agent_bots(bots_data)
    return unless bots_data

    bots_data.each do |bot_data|
      @account.agent_bots.create!(
        name: bot_data['name'],
        description: bot_data['description'],
        outgoing_url: bot_data['outgoing_url']
      )
    end
  end

  def restore_campaigns(campaigns_data)
    return unless campaigns_data

    campaigns_data.each do |campaign_data|
      @account.campaigns.create!(
        title: campaign_data['title'],
        description: campaign_data['description'],
        message: campaign_data['message'],
        enabled: campaign_data['enabled'],
        campaign_type: campaign_data['campaign_type'],
        campaign_status: campaign_data['campaign_status'],
        audience: campaign_data['audience'],
        trigger_rules: campaign_data['trigger_rules']
      )
    end
  end

  def restore_inboxes(inboxes_data)
    return unless inboxes_data

    inboxes_data.each do |inbox_data|
      # Cria canal baseado no tipo
      channel = create_channel_from_data(inbox_data['channel'])
      next unless channel

      inbox = @account.inboxes.create!(
        name: inbox_data['name'],
        channel: channel,
        enable_auto_assignment: inbox_data['enable_auto_assignment'],
        greeting_enabled: inbox_data['greeting_enabled'],
        greeting_message: inbox_data['greeting_message'],
        working_hours_enabled: inbox_data['working_hours_enabled'],
        out_of_office_message: inbox_data['out_of_office_message'],
        timezone: inbox_data['timezone'],
        allow_messages_after_resolved: inbox_data['allow_messages_after_resolved']
      )

      @inbox_mapping[inbox_data['id']] = inbox.id

      # Restaura membros do inbox
      inbox_data['inbox_members']&.each do |im_data|
        next unless @user_mapping[im_data['user_id']]

        inbox.inbox_members.create!(
          user_id: @user_mapping[im_data['user_id']]
        )
      end
    end
  end

  def create_channel_from_data(channel_data)
    return nil unless channel_data

    case channel_data['type']
    when 'Channel::WebWidget'
      @account.web_widgets.create!(
        website_name: channel_data['website_name'],
        website_url: channel_data['website_url'],
        widget_color: channel_data['widget_color'],
        welcome_title: channel_data['welcome_title'],
        welcome_tagline: channel_data['welcome_tagline'],
        feature_flags: channel_data['feature_flags']
      )
    when 'Channel::Email'
      @account.email_channels.create!(
        email: channel_data['email'],
        forward_to_email: channel_data['forward_to_email'],
        imap_enabled: channel_data['imap_enabled'],
        imap_address: channel_data['imap_address'],
        imap_port: channel_data['imap_port'],
        imap_login: channel_data['imap_login'],
        imap_password: channel_data['imap_password'],
        smtp_enabled: channel_data['smtp_enabled'],
        smtp_address: channel_data['smtp_address'],
        smtp_port: channel_data['smtp_port'],
        smtp_login: channel_data['smtp_login'],
        smtp_password: channel_data['smtp_password']
      )
    when 'Channel::Api'
      @account.api_channels.create!(
        webhook_url: channel_data['webhook_url']
      )
    else
      Rails.logger.warn "Tipo de canal não suportado: #{channel_data['type']}"
      nil
    end
  end

  def restore_contacts(contacts_data)
    return unless contacts_data

    contacts_data.each do |contact_data|
      contact = @account.contacts.create!(
        name: contact_data['name'],
        email: contact_data['email'],
        phone_number: contact_data['phone_number'],
        additional_attributes: contact_data['additional_attributes'],
        custom_attributes: contact_data['custom_attributes'],
        identifier: contact_data['identifier']
      )

      @contact_mapping[contact_data['id']] = contact.id
    end
  end

  def restore_conversations(conversations_data)
    return unless conversations_data

    conversations_data.each do |conv_data|
      next unless @contact_mapping[conv_data['contact_id']] && @inbox_mapping[conv_data['inbox_id']]

      @account.conversations.create!(
        contact_id: @contact_mapping[conv_data['contact_id']],
        inbox_id: @inbox_mapping[conv_data['inbox_id']],
        status: conv_data['status'],
        assignee_id: @user_mapping[conv_data['assignee_id']],
        team_id: @team_mapping[conv_data['team_id']],
        additional_attributes: conv_data['additional_attributes'],
        custom_attributes: conv_data['custom_attributes'],
        snoozed_until: conv_data['snoozed_until'],
        identifier: conv_data['identifier']
      )
    end
  end

  def restore_messages(messages_data)
    return unless messages_data

    messages_data.each do |message_data|
      next unless @account.conversations.find_by(id: message_data['conversation_id'])

      @account.messages.create!(
        content: message_data['content'],
        message_type: message_data['message_type'],
        private: message_data['private'],
        status: message_data['status'],
        source_id: message_data['source_id'],
        content_type: message_data['content_type'],
        content_attributes: message_data['content_attributes'],
        conversation_id: message_data['conversation_id'],
        inbox_id: @inbox_mapping[message_data['inbox_id']],
        user_id: @user_mapping[message_data['user_id']],
        contact_id: @contact_mapping[message_data['contact_id']]
      )
    end
  end

  def restore_notes(notes_data)
    return unless notes_data

    notes_data.each do |note_data|
      next unless @contact_mapping[note_data['contact_id']]

      @account.notes.create!(
        content: note_data['content'],
        contact_id: @contact_mapping[note_data['contact_id']],
        user_id: @user_mapping[note_data['user_id']]
      )
    end
  end

  def restore_notification_settings(settings_data)
    return unless settings_data

    settings_data.each do |setting_data|
      next unless @user_mapping[setting_data['user_id']]

      @account.notification_settings.create!(
        user_id: @user_mapping[setting_data['user_id']],
        email_flags: setting_data['email_flags'],
        push_flags: setting_data['push_flags']
      )
    end
  end

  def restore_portals(portals_data)
    return unless portals_data

    portals_data.each do |portal_data|
      @account.portals.create!(
        name: portal_data['name'],
        slug: portal_data['slug'],
        custom_domain: portal_data['custom_domain'],
        color: portal_data['color'],
        homepage_link: portal_data['homepage_link'],
        page_title: portal_data['page_title'],
        header_text: portal_data['header_text'],
        config: portal_data['config']
      )
    end
  end

  def restore_categories(categories_data)
    return unless categories_data

    categories_data.each do |category_data|
      @account.categories.create!(
        name: category_data['name'],
        description: category_data['description'],
        position: category_data['position'],
        locale: category_data['locale'],
        slug: category_data['slug'],
        portal_id: category_data['portal_id']
      )
    end
  end

  def restore_articles(articles_data)
    return unless articles_data

    articles_data.each do |article_data|
      @account.articles.create!(
        title: article_data['title'],
        content: article_data['content'],
        description: article_data['description'],
        status: article_data['status'],
        position: article_data['position'],
        locale: article_data['locale'],
        slug: article_data['slug'],
        meta: article_data['meta'],
        views: article_data['views'],
        portal_id: article_data['portal_id'],
        category_id: article_data['category_id'],
        folder_id: article_data['folder_id'],
        author_id: @user_mapping[article_data['author_id']] || @account.users.first&.id
      )
    end
  end
end 