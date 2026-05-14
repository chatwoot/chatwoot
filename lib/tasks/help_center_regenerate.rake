namespace :help_center do
  desc 'Ad-hoc: refresh brand info (optional) and trigger help center generation for account 5'
  task regenerate: :environment do
    account = Account.find(5)
    current_domain = account.custom_attributes['website'].presence ||
                     account.custom_attributes.dig('brand_info', 'domain')

    print "Domain [#{current_domain}]: "
    input = $stdin.gets.to_s.strip
    new_domain = input.presence

    if new_domain && new_domain != current_domain
      puts "Fetching brand info for #{new_domain}..."
      result = WebsiteBrandingService.new("noreply@#{new_domain}").perform
      abort 'Brand fetch failed' if result.blank?

      account.name = result[:title] if result[:title].present?
      account.custom_attributes['website'] = new_domain
      account.custom_attributes['brand_info'] = result
      account.save!
      puts 'Updated custom_attributes.'
    else
      puts 'Domain unchanged.'
    end

    user = account.users.first
    abort 'No user on account' if user.nil?

    if account.portals.any?
      puts "Destroying #{account.portals.count} existing portal(s)..."
      account.portals.destroy_all
    end

    puts "Triggering Onboarding::HelpCenterCreationService for account #{account.id}..."
    Onboarding::HelpCenterCreationService.new(account, user).perform
    puts 'Done.'
  end
end
