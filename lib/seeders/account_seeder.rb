## Class to generate sample data for a chatwoot test @Account.
############################################################
### Usage #####
#
#   # Seed an account with all data types in this class
#   Seeders::AccountSeeder.new(account: Account.find(1)).perform!
#
#
############################################################

class Seeders::AccountSeeder
  def initialize(account:)
    raise 'Account Seeding is not allowed.' unless ENV.fetch('ENABLE_ACCOUNT_SEEDING', !Rails.env.production?)

    @account_data = ActiveSupport::HashWithIndifferentAccess.new(YAML.safe_load(Rails.root.join('lib/seeders/seed_data.yml').read))
    @account = account
  end

  def perform!
    set_up_account
    seed_teams
    seed_custom_roles
    set_up_users
    seed_labels
    seed_canned_responses
    seed_macros
    seed_inboxes
    seed_contacts
    seed_portals
    seed_captain_assistants
    finalize_seeding
  end

  def set_up_account
    # Delete all existing data before seeding
    @account.macros.destroy_all
    @account.canned_responses.destroy_all
    @account.teams.destroy_all
    @account.conversations.destroy_all
    @account.labels.destroy_all
    @account.portals.destroy_all
    @account.inboxes.destroy_all
    @account.contacts.destroy_all
    @account.custom_roles.destroy_all if @account.respond_to?(:custom_roles)

    # Delete Captain Assistants if Enterprise feature is available
    return unless defined?(Captain::Assistant)

    Captain::Assistant.where(account_id: @account.id).destroy_all
  end

  def seed_teams
    @account_data['teams'].each do |team_data|
      if team_data.is_a?(String)
        # Support legacy format (just team name)
        @account.teams.create!(name: team_data)
      else
        # New format with name and description
        @account.teams.create!(
          name: team_data['name'],
          description: team_data['description'],
          allow_auto_assign: team_data['allow_auto_assign'] != false
        )
      end
    end
  end

  def seed_custom_roles
    return unless @account_data['custom_roles'].present? && @account.respond_to?(:custom_roles)

    @account_data['custom_roles'].each do |role_data|
      @account.custom_roles.create!(
        name: role_data['name'],
        description: role_data['description'],
        permissions: role_data['permissions']
      )
    end
  end

  def seed_labels
    @account_data['labels'].each do |label|
      @account.labels.create!(label)
    end
  end

  def set_up_users
    @account_data['users'].each do |user|
      user_record = create_user_record(user)
      create_account_user(user_record, user)
      add_user_to_teams(user: user_record, teams: user['team']) if user['team'].present?
    end
  end

  private

  def create_user_record(user)
    user_record = User.create_with(name: user['name'], password: 'Password1!.').find_or_create_by!(email: user['email'].to_s)
    user_record.skip_confirmation!
    user_record.save!
    Avatar::AvatarFromUrlJob.perform_later(user_record, "https://xsgames.co/randomusers/avatar.php?g=#{user['gender']}")
    user_record
  end

  def create_account_user(user_record, user)
    account_user_attrs = build_account_user_attrs(user)
    AccountUser.create_with(account_user_attrs).find_or_create_by!(account_id: @account.id, user_id: user_record.id)
  end

  def build_account_user_attrs(user)
    attrs = { role: (user['role'] || 'agent') }
    custom_role = find_custom_role(user['custom_role']) if user['custom_role'].present?
    attrs[:custom_role] = custom_role if custom_role
    attrs
  end

  def add_user_to_teams(user:, teams:)
    teams.each do |team|
      team_record = @account.teams.where('name LIKE ?', "%#{team.downcase}%").first if team.present?
      TeamMember.find_or_create_by!(team_id: team_record.id, user_id: user.id) unless team_record.nil?
    end
  end

  def find_custom_role(role_name)
    return nil unless @account.respond_to?(:custom_roles)

    @account.custom_roles.find_by(name: role_name)
  end

  def seed_canned_responses
    return unless @account_data['canned_responses'].present?

    @account_data['canned_responses'].each do |response|
      @account.canned_responses.create!(response)
    end
  end

  def seed_macros
    return unless @account_data['macros'].present?

    @account_data['macros'].each do |macro_data|
      created_by = User.from_email(macro_data['created_by']) if macro_data['created_by'].present?
      actions = macro_data['actions'].map do |action|
        process_macro_action(action)
      end.compact # Remove nil actions (when team/agent not found)

      # Only create macro if there are valid actions
      if actions.any?
        @account.macros.create!(
          name: macro_data['name'],
          visibility: macro_data['visibility'] || 'global',
          created_by: created_by,
          actions: actions
        )
      else
        Rails.logger.warn("Macro '#{macro_data['name']}' has no valid actions, skipping")
      end
    end
  end

  def seed_portals
    return unless @account_data['portals'].present?

    @account_data['portals'].each do |portal_data|
      portal = @account.portals.create!(
        name: portal_data['name'],
        slug: portal_data['slug'],
        page_title: portal_data['page_title'],
        header_text: portal_data['header_text'],
        color: portal_data['color'],
        config: portal_data['config']
      )

      seed_portal_categories(portal, portal_data['categories']) if portal_data['categories'].present?
    end
  end

  def seed_captain_assistants
    return unless @account_data['captain_assistants'].present?
    return unless defined?(Captain::Assistant)

    @account_data['captain_assistants'].each do |assistant_data|
      assistant = Captain::Assistant.create!(
        account: @account,
        name: assistant_data['name'],
        description: assistant_data['description'],
        config: assistant_data['config'] || {}
      )

      seed_captain_documents(assistant, assistant_data['documents']) if assistant_data['documents'].present?
      seed_captain_scenarios(assistant, assistant_data['scenarios']) if assistant_data['scenarios'].present?
    end
  end

  def seed_contacts
    @account_data['contacts'].each do |contact_data|
      contact = @account.contacts.find_or_initialize_by(email: contact_data['email'])
      if contact.new_record?
        contact.update!(contact_data.slice('name', 'email'))
        Avatar::AvatarFromUrlJob.perform_later(contact, "https://xsgames.co/randomusers/avatar.php?g=#{contact_data['gender']}")
      end
      contact_data['conversations'].each do |conversation_data|
        inbox = @account.inboxes.find_by(channel_type: conversation_data['channel'])
        contact_inbox = inbox.contact_inboxes.create_or_find_by!(contact: contact, source_id: (conversation_data['source_id'] || SecureRandom.hex))
        create_conversation(contact_inbox: contact_inbox, conversation_data: conversation_data)
      end
    end
  end

  def create_conversation(contact_inbox:, conversation_data:)
    assignee = User.from_email(conversation_data['assignee']) if conversation_data['assignee'].present?
    conversation = contact_inbox.conversations.create!(account: contact_inbox.inbox.account, contact: contact_inbox.contact,
                                                       inbox: contact_inbox.inbox, assignee: assignee)
    create_messages(conversation: conversation, messages: conversation_data['messages'])
    conversation.update_labels(conversation_data[:labels]) if conversation_data[:labels].present?
    conversation.update!(priority: conversation_data[:priority]) if conversation_data[:priority].present?
  end

  def create_messages(conversation:, messages:)
    messages.each do |message_data|
      sender = find_message_sender(conversation, message_data)
      conversation.messages.create!(
        message_data.slice('content', 'message_type').merge(
          account: conversation.inbox.account, sender: sender, inbox: conversation.inbox
        )
      )
    end
  end

  def find_message_sender(conversation, message_data)
    if message_data['message_type'] == 'incoming'
      conversation.contact
    elsif message_data['sender'].present?
      User.from_email(message_data['sender'])
    end
  end

  def seed_inboxes
    Seeders::InboxSeeder.new(account: @account, company_data: @account_data[:company]).perform!
  end

  def process_macro_action(action)
    processed_action = { 'action_name' => action['action_name'] }

    case action['action_name']
    when 'assign_team'
      team = @account.teams.find_by('name LIKE ?', "%#{action['action_params'][0]}%")
      if team
        processed_action['action_params'] = [team.id]
      else
        Rails.logger.warn("Macro: Team not found matching '#{action['action_params'][0]}', skipping assign_team action")
        return nil # Skip this action
      end
    when 'assign_agent'
      user = User.from_email(action['action_params'][0])
      if user
        processed_action['action_params'] = [user.id]
      else
        Rails.logger.warn("Macro: User not found '#{action['action_params'][0]}', skipping assign_agent action")
        return nil # Skip this action
      end
    else
      processed_action['action_params'] = action['action_params']
    end

    processed_action
  end

  def seed_portal_categories(portal, categories_data)
    categories_data.each do |category_data|
      category = portal.categories.create!(
        account: @account,
        name: category_data['name'],
        slug: category_data['slug'],
        description: category_data['description'],
        locale: category_data['locale'] || 'en',
        position: category_data['position']
      )

      seed_category_articles(portal, category, category_data['articles']) if category_data['articles'].present?
    end
  end

  def seed_category_articles(portal, category, articles_data)
    articles_data.each do |article_data|
      author = User.from_email(article_data['author']) if article_data['author'].present?
      author ||= @account.users.administrators.first

      portal.articles.create!(
        account: @account,
        category: category,
        author: author,
        title: article_data['title'],
        description: article_data['description'],
        content: article_data['content'],
        status: article_data['status'] || 'published',
        locale: article_data['locale'] || 'en'
      )
    end
  end

  def seed_captain_documents(assistant, documents_data)
    documents_data.each do |doc_data|
      Captain::Document.create!(
        account: @account,
        assistant: assistant,
        name: doc_data['name'],
        external_link: doc_data['external_link'],
        content: doc_data['content'],
        status: doc_data['status'] || 'available'
      )
    end
  end

  def seed_captain_scenarios(assistant, scenarios_data)
    scenarios_data.each do |scenario_data|
      Captain::Scenario.create!(
        account: @account,
        assistant: assistant,
        title: scenario_data['title'],
        description: scenario_data['description'],
        instruction: scenario_data['instruction'],
        enabled: scenario_data['enabled'] != false
      )
    end
  end

  def finalize_seeding
    # Reload account to ensure all associations are fresh
    @account.reload

    # Reset cache keys for labels, inboxes, teams
    @account.reset_cache_keys if @account.respond_to?(:reset_cache_keys)

    # Clear any Rails cache related to this account
    Rails.cache.delete("account/#{@account.id}")

    # Force reload of all account users to refresh their associations
    @account.account_users.each(&:reload)

    Rails.logger.info("Seed completed for account #{@account.id} - #{@account.name}")
  end
end
