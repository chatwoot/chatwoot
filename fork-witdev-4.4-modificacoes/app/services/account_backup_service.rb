class AccountBackupService
  def initialize(account)
    @account = account
  end

  def create_backup
    backup_data = {
      version: '1.0',
      created_at: Time.current.iso8601,
      account_data: serialize_account_data,
      related_data: serialize_related_data
    }

    filename = "account_#{@account.id}_backup_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json"
    
    {
      data: backup_data,
      filename: filename,
      size: backup_data.to_json.bytesize
    }
  end

  private

  def serialize_account_data
    @account.as_json(
      except: [:created_at, :updated_at],
      include: {
        account_users: {
          except: [:created_at, :updated_at],
          include: {
            user: {
              only: [:id, :name, :email, :display_name, :provider, :uid, :custom_attributes]
            }
          }
        }
      }
    )
  end

  def serialize_related_data
    {
      contacts: serialize_contacts,
      conversations: serialize_conversations,
      messages: serialize_messages,
      inboxes: serialize_inboxes,
      teams: serialize_teams,
      labels: serialize_labels,
      canned_responses: serialize_canned_responses,
      automation_rules: serialize_automation_rules,
      macros: serialize_macros,
      custom_attribute_definitions: serialize_custom_attributes,
      webhooks: serialize_webhooks,
      notes: serialize_notes,
      campaigns: serialize_campaigns,
      agent_bots: serialize_agent_bots,
      working_hours: serialize_working_hours,
      notification_settings: serialize_notification_settings,
      custom_filters: serialize_custom_filters,
      portals: serialize_portals,
      articles: serialize_articles,
      categories: serialize_categories
    }
  end

  def serialize_contacts
    @account.contacts.includes(:contact_inboxes, :additional_attributes).map do |contact|
      contact.as_json(
        except: [:created_at, :updated_at],
        include: {
          contact_inboxes: { except: [:created_at, :updated_at] },
          additional_attributes: { except: [:created_at, :updated_at] }
        }
      )
    end
  end

  def serialize_conversations
    @account.conversations.includes(:messages, :assignee, :team, :contact_inbox).map do |conversation|
      conversation.as_json(
        except: [:created_at, :updated_at],
        include: {
          contact_inbox: { except: [:created_at, :updated_at] },
          assignee: { only: [:id, :name, :email] },
          team: { only: [:id, :name] }
        }
      )
    end
  end

  def serialize_messages
    @account.messages.includes(:attachments, :content_attributes).map do |message|
      message.as_json(
        except: [:created_at, :updated_at],
        include: {
          attachments: { except: [:created_at, :updated_at] },
          content_attributes: { except: [:created_at, :updated_at] }
        }
      )
    end
  end

  def serialize_inboxes
    @account.inboxes.includes(:channel, :inbox_members, :agent_bot_inboxes).map do |inbox|
      inbox.as_json(
        except: [:created_at, :updated_at],
        include: {
          channel: { except: [:created_at, :updated_at] },
          inbox_members: { except: [:created_at, :updated_at] },
          agent_bot_inboxes: { except: [:created_at, :updated_at] }
        }
      )
    end
  end

  def serialize_teams
    @account.teams.includes(:team_members).map do |team|
      team.as_json(
        except: [:created_at, :updated_at],
        include: {
          team_members: { except: [:created_at, :updated_at] }
        }
      )
    end
  end

  def serialize_labels
    @account.labels.map { |label| label.as_json(except: [:created_at, :updated_at]) }
  end

  def serialize_canned_responses
    @account.canned_responses.map { |response| response.as_json(except: [:created_at, :updated_at]) }
  end

  def serialize_automation_rules
    @account.automation_rules.map { |rule| rule.as_json(except: [:created_at, :updated_at]) }
  end

  def serialize_macros
    @account.macros.map { |macro| macro.as_json(except: [:created_at, :updated_at]) }
  end

  def serialize_custom_attributes
    @account.custom_attribute_definitions.map { |attr| attr.as_json(except: [:created_at, :updated_at]) }
  end

  def serialize_webhooks
    @account.webhooks.map { |webhook| webhook.as_json(except: [:created_at, :updated_at]) }
  end

  def serialize_notes
    @account.notes.map { |note| note.as_json(except: [:created_at, :updated_at]) }
  end

  def serialize_campaigns
    @account.campaigns.map { |campaign| campaign.as_json(except: [:created_at, :updated_at]) }
  end

  def serialize_agent_bots
    @account.agent_bots.map { |bot| bot.as_json(except: [:created_at, :updated_at]) }
  end

  def serialize_working_hours
    @account.working_hours.map { |wh| wh.as_json(except: [:created_at, :updated_at]) }
  end

  def serialize_notification_settings
    @account.notification_settings.map { |ns| ns.as_json(except: [:created_at, :updated_at]) }
  end

  def serialize_custom_filters
    @account.custom_filters.map { |filter| filter.as_json(except: [:created_at, :updated_at]) }
  end

  def serialize_portals
    @account.portals.includes(:categories, :articles).map do |portal|
      portal.as_json(
        except: [:created_at, :updated_at],
        include: {
          categories: { except: [:created_at, :updated_at] },
          articles: { except: [:created_at, :updated_at] }
        }
      )
    end
  end

  def serialize_articles
    @account.articles.map { |article| article.as_json(except: [:created_at, :updated_at]) }
  end

  def serialize_categories
    @account.categories.map { |category| category.as_json(except: [:created_at, :updated_at]) }
  end
end 