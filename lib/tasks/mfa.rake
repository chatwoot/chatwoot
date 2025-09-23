module MfaTasks
  def self.find_user_or_exit(email)
    abort 'Error: Please provide an email address' if email.blank?
    user = User.from_email(email)
    abort "Error: User with email '#{email}' not found" unless user
    user
  end

  def self.reset_user_mfa(user)
    user.update!(
      otp_required_for_login: false,
      otp_secret: nil,
      otp_backup_codes: nil
    )
  end

  def self.reset_single(args)
    user = find_user_or_exit(args[:email])
    abort "MFA is already disabled for #{args[:email]}" if !user.otp_required_for_login? && user.otp_secret.nil?
    reset_user_mfa(user)
    puts "✓ MFA has been successfully reset for #{args[:email]}"
  rescue StandardError => e
    abort "Error resetting MFA: #{e.message}"
  end

  def self.reset_all
    print 'Are you sure you want to reset MFA for ALL users? This cannot be undone! (yes/no): '
    abort 'Operation cancelled' unless $stdin.gets.chomp.downcase == 'yes'

    affected_users = User.where(otp_required_for_login: true).or(User.where.not(otp_secret: nil))
    count = affected_users.count
    abort 'No users have MFA enabled' if count.zero?

    puts "\nResetting MFA for #{count} user(s)..."
    affected_users.find_each { |user| reset_user_mfa(user) }
    puts "✓ MFA has been reset for #{count} user(s)"
  end

  def self.generate_backup_codes(args)
    user = find_user_or_exit(args[:email])
    abort "Error: MFA is not enabled for #{args[:email]}" unless user.otp_required_for_login?

    service = Mfa::ManagementService.new(user: user)
    codes = service.generate_backup_codes!
    puts "\nNew backup codes generated for #{args[:email]}:"
    codes.each { |code| puts code }
  end
end

namespace :mfa do
  desc 'Reset MFA for a specific user by email'
  task :reset, [:email] => :environment do |_task, args|
    MfaTasks.reset_single(args)
  end

  desc 'Reset MFA for all users in the system'
  task reset_all: :environment do
    MfaTasks.reset_all
  end

  desc 'Generate new backup codes for a user'
  task :generate_backup_codes, [:email] => :environment do |_task, args|
    MfaTasks.generate_backup_codes(args)
  end
end
