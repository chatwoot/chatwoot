namespace :mfa do
  desc 'Reset MFA for a specific user by email'
  task :reset, [:email] => :environment do |_task, args|
    email = args[:email]

    if email.blank?
      puts 'Error: Please provide an email address'
      puts 'Usage: rails mfa:reset[user@example.com]'
      exit 1
    end

    user = User.find_by(email: email)

    if user.nil?
      puts "Error: User with email '#{email}' not found"
      exit 1
    end

    # Check if MFA is already disabled
    if !user.otp_required_for_login? && user.otp_secret.nil?
      puts "MFA is already disabled for #{email}"
      exit 0
    end

    # Reset MFA settings
    user.update!(
      otp_required_for_login: false,
      otp_secret: nil,
      otp_backup_codes: nil
    )

    puts "✓ MFA has been successfully reset for #{email}"
    puts "  - Two-factor authentication: Disabled"
    puts "  - OTP secret: Removed"
    puts "  - Backup codes: Cleared"
    puts "\nThe user can now log in with just their password and re-enable MFA if desired."
  rescue StandardError => e
    puts "Error resetting MFA: #{e.message}"
    exit 1
  end

  desc 'Reset MFA for all users in the system'
  task reset_all: :environment do
    print 'Are you sure you want to reset MFA for ALL users? This cannot be undone! (yes/no): '
    confirmation = $stdin.gets.chomp.downcase

    unless confirmation == 'yes'
      puts 'Operation cancelled'
      exit 0
    end

    affected_users = User.where(otp_required_for_login: true).or(User.where.not(otp_secret: nil))
    count = affected_users.count

    if count.zero?
      puts 'No users have MFA enabled'
      exit 0
    end

    puts "\nResetting MFA for #{count} user(s)..."

    affected_users.update_all(
      otp_required_for_login: false,
      otp_secret: nil,
      otp_backup_codes: nil
    )

    puts "✓ MFA has been reset for #{count} user(s)"
    puts "\nAll users can now log in with just their passwords."
  end

  desc 'Generate new backup codes for a user'
  task :generate_backup_codes, [:email] => :environment do |_task, args|
    email = args[:email]

    if email.blank?
      puts 'Error: Please provide an email address'
      puts 'Usage: rails mfa:generate_backup_codes[user@example.com]'
      exit 1
    end

    user = User.find_by(email: email)

    if user.nil?
      puts "Error: User with email '#{email}' not found"
      exit 1
    end

    unless user.otp_required_for_login?
      puts "Error: MFA is not enabled for #{email}"
      puts 'The user must enable MFA first before generating backup codes'
      exit 1
    end

    # Generate new backup codes
    service = Mfa::ManagementService.new(user: user)
    codes = service.generate_backup_codes!

    puts "\nNew backup codes generated for #{email}:"
    puts "━" * 40
    codes.each_with_index do |code, index|
      puts "#{index + 1}. #{code}"
    end
    puts "━" * 40
    puts "\n⚠ Important: Share these codes securely with the user"
    puts "Each code can only be used once"
  end
end