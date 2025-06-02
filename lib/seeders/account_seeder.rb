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
    seed_inboxes
    seed_contacts
    seed_csat_responses
  end

  def set_up_account
    @account.teams.destroy_all
    @account.conversations.destroy_all
    @account.labels.destroy_all
    @account.inboxes.destroy_all
    @account.contacts.destroy_all
    @account.custom_roles.destroy_all if @account.respond_to?(:custom_roles)
  end

  def seed_teams
    @account_data['teams'].each do |team_name|
      @account.teams.create!(name: team_name)
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

  def seed_canned_responses(count: 50)
    count.times do
      @account.canned_responses.create(content: Faker::Quote.fortune_cookie, short_code: Faker::Alphanumeric.alpha(number: 10))
    end
  end

  def seed_contacts
    @account_data['contacts'].each do |contact_data|
      contact = @account.contacts.find_or_initialize_by(email: contact_data['email'])
      if contact.new_record?
        contact.update!(contact_data.slice('name', 'email'))
        Avatar::AvatarFromUrlJob.perform_later(contact, "https://xsgames.co/randomusers/avatar.php?g=#{contact_data['gender']}")
      end
    end

    # Create conversations after all contacts are created
    Seeders::ConversationSeeder.new(account: @account, contact_data: @account_data['contacts']).perform!
  end

  def seed_inboxes
    Seeders::InboxSeeder.new(account: @account, company_data: @account_data[:company]).perform!
  end

  def seed_csat_responses
    Seeders::CsatSeeder.new(account: @account).perform!
  end
end
