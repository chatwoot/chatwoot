# frozen_string_literal: true

class AccountBuilder
  include CustomExceptions::Account
  pattr_initialize [:account_name!, :email!]

  def perform
    validate_email
    validate_user
    ActiveRecord::Base.transaction do
      @account = create_account
      @user = create_and_link_user
    end
  rescue StandardError => e
    @account&.destroy
    puts e.inspect
    raise e
  end

  private

  def validate_email
    address = ValidEmail2::Address.new(@email)
    if address.valid? # && !address.disposable?
      true
    else
      raise InvalidEmail.new(valid: address.valid?) # , disposable: address.disposable?})
    end
  end

  def validate_user
    if User.exists?(email: @email)
      raise UserExists.new(email: @email)
    else
      true
    end
  end

  def create_account
    @account = Account.create!(name: @account_name)
  end

  def create_and_link_user
    password = Time.now.to_i
    @user = @account.users.new(email: @email,
                               password: password,
                               password_confirmation: password,
                               role: User.roles['administrator'],
                               name: email_to_name(@email))
    if @user.save!
      @user
    else
      raise UserErrors.new(errors: @user.errors)
    end
  end

  def email_to_name(email)
    name = email[/[^@]+/]
    name.split('.').map(&:capitalize).join(' ')
  end
end
