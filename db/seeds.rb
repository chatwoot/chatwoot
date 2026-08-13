# loading installation configs
GlobalConfig.clear_cache
ConfigLoader.new.process

## Seeds productions
if Rails.env.production?
  # Setup Onboarding flow
  Redis::Alfred.set(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING, true)
end

## Seeds for Local Development
unless Rails.env.production?

  # Enables creating additional accounts from dashboard
  installation_config = InstallationConfig.find_by(name: 'CREATE_NEW_ACCOUNT_FROM_DASHBOARD')
  installation_config.value = true
  installation_config.save!
  GlobalConfig.clear_cache

  # Idempotent: this block is safe to re-run (e.g. repeated `rails db:seed`).
  account = Account.find_or_create_by!(name: 'Acme Inc')

  secondary_account = Account.find_or_create_by!(name: 'Acme Org')

  user = User.find_or_initialize_by(email: 'john@acme.inc')
  user.name = 'John'
  user.password = 'Password1!'
  user.type = 'SuperAdmin'
  user.skip_confirmation!
  user.save!

  AccountUser.find_or_create_by!(account_id: account.id, user_id: user.id) { |account_user| account_user.role = :administrator }
  AccountUser.find_or_create_by!(account_id: secondary_account.id, user_id: user.id) { |account_user| account_user.role = :administrator }

  # Sample conversations/messages are only created once per account.
  unless Inbox.exists?(account: account, name: 'Acme Support')
    web_widget = Channel::WebWidget.create!(account: account, website_url: 'https://acme.inc')

    inbox = Inbox.create!(channel: web_widget, account: account, name: 'Acme Support')
    InboxMember.create!(user: user, inbox: inbox)

    contact_inbox = ContactInboxWithContactBuilder.new(
      source_id: user.id,
      inbox: inbox,
      hmac_verified: true,
      contact_attributes: { name: 'jane', email: 'jane@example.com', phone_number: '+2320000' }
    ).perform

    conversation = Conversation.create!(
      account: account,
      inbox: inbox,
      status: :open,
      assignee: user,
      contact: contact_inbox.contact,
      contact_inbox: contact_inbox,
      additional_attributes: {}
    )

    # sample email collect
    Seeders::MessageSeeder.create_sample_email_collect_message conversation

    Message.create!(content: 'Hello', account: account, inbox: inbox, conversation: conversation, sender: contact_inbox.contact,
                    message_type: :incoming)

    # sample location message
    #
    location_message = Message.new(content: 'location', account: account, inbox: inbox, sender: contact_inbox.contact, conversation: conversation,
                                   message_type: :incoming)
    location_message.attachments.new(
      account_id: account.id,
      file_type: 'location',
      coordinates_lat: 37.7893768,
      coordinates_long: -122.3895553,
      fallback_title: 'Bay Bridge, San Francisco, CA, USA'
    )
    location_message.save!

    # sample card
    Seeders::MessageSeeder.create_sample_cards_message conversation
    # input select
    Seeders::MessageSeeder.create_sample_input_select_message conversation
    # form
    Seeders::MessageSeeder.create_sample_form_message conversation
    # articles
    Seeders::MessageSeeder.create_sample_articles_message conversation
    # csat
    Seeders::MessageSeeder.create_sample_csat_collect_message conversation

    CannedResponse.create!(account: account, short_code: 'start', content: 'Hello welcome to chatwoot.')
  end

  # --------------------------------------------------------------------------
  # Demo account + base plan + super-admin user for local review.
  #
  # The Demo Account needs an active package assignment (created below) or it
  # would be treated as inactive by the package-driven account gating added in
  # the Super Admin Packages feature. Idempotent: safe to re-run db:seed.
  # --------------------------------------------------------------------------
  demo_account = Account.find_or_create_by!(name: 'Demo Account') do |demo|
    demo.status = :active
  end

  # Mark the Demo Account as an Enterprise plan so enterprise feature-sync logic
  # (e.g. auto-enabling advanced_assignment with assignment_v2) keeps it unlocked.
  demo_account.custom_attributes['plan_name'] = 'Enterprise'
  demo_account.save!

  # Only create a base plan if the Demo Account does not already have a current,
  # active one (it may have been assigned earlier from the Super Admin Packages
  # page during local testing).
  demo_assignment = demo_account.account_packages
                                .current
                                .joins(:package)
                                .where(packages: { status: Package.statuses[:active] })
                                .order(:starts_at)
                                .last
  unless demo_assignment
    demo_package = Package.find_or_initialize_by(name: 'Demo Plan')
    demo_package.description = 'Base plan for the Demo Account'
    demo_package.status = :active
    demo_package.users_limit = 5
    demo_package.channels_limit = 5
    demo_package.contacts_limit = 500
    demo_package.conversations_limit = 500
    demo_package.campaign_messages_limit = 500
    demo_package.save!

    demo_account.account_packages.create!(
      package: demo_package,
      starts_at: 1.month.ago,
      ends_at: 11.months.from_now
    )
  end

  # Permanently unlock the premium features. The instance self-identifies as
  # enterprise (INSTALLATION_PRICING_PLAN) — this kills the frontend paywalls
  # (enterprise + community plan is what made them show) and stops the daily
  # Internal::ReconcilePlanConfigService from force-disabling premium features.
  # The 12 premium flags are also enabled by default for every account via
  # config/features.yml; here we make sure the Demo Account has them on too.
  # Idempotent: safe to re-run db:seed.
  installation_config = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN')
  installation_config.value = 'enterprise'
  installation_config.save!
  # Drop any cached copy of the plan so the running app and frontend pick up the
  # enterprise plan immediately instead of serving a stale 'community' for a day.
  GlobalConfig.clear_cache

  PREMIUM_FEATURES_TO_UNLOCK = %w[
    advanced_assignment advanced_search audit_logs csat_review_notes companies
    custom_roles custom_tools disable_branding conversation_required_attributes
    saml sla channel_voice
  ].freeze
  demo_account.enable_features!(*PREMIUM_FEATURES_TO_UNLOCK)

  demo_user = User.find_or_initialize_by(email: 'investor.hamada@gmail.com')
  demo_user.name = 'Investor'
  demo_user.display_name = 'Investor'
  demo_user.password = 'Aa@123456789'
  demo_user.type = 'SuperAdmin'
  demo_user.skip_confirmation!
  demo_user.save!

  AccountUser.find_or_create_by!(account_id: demo_account.id, user_id: demo_user.id) do |account_user|
    account_user.role = :administrator
  end
end
