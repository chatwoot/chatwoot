class Migration::GenerateDigitaltolkTokenJob < ApplicationJob
  queue_as :scheduled_jobs
  EMAIL = ENV.fetch('DT_ADMIN_USERNAME', nil)
  PASS = ENV.fetch('DT_ADMIN_PASSWORD', nil)

  def perform
    user = nil
    return if EMAIL.blank? && PASS.blank?

    ActiveRecord::Base.transaction do
      user = find_or_create_user

      Account.all.find_each do |account|
        next if AccountUser.exists?(account_id: account.id, user_id: user.id)

        create_account_user(account, user)
      end
    end

    begin
      create_user_auth(user)
    rescue StandardError => e
      Rails.logger.error e
    end
  end

  private

  def find_or_create_user
    User.from_email(EMAIL) || User.create!(
      uid: EMAIL,
      email: EMAIL,
      password: PASS,
      display_name: 'Engineering Chatwoot',
      name: 'Engineering Chatwoot'
    )
  end

  def create_user_auth(user)
    result = Digitaltolk::Auth::Generate.new(EMAIL, PASS).perform
    return if result.blank?

    Digitaltolk::Auth::UpdateUserAuth.new(user, result).perform
  end

  def create_account_user(account, user)
    return if account.blank? || user.blank?

    AccountUser.create!(
      account_id: account.id,
      user_id: user.id,
      role: AccountUser.roles['administrator']
    )
  end
end
