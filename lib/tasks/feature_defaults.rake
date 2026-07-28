# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :feature_defaults do
  desc 'Interactively toggle a feature on/off in ACCOUNT_LEVEL_FEATURE_DEFAULTS (affects new account signups only)'
  task toggle: :environment do
    config = InstallationConfig.find_by!(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')

    loop do
      features = config.value
      print_feature_list(features)

      print "\nEnter the number of the feature to toggle (or 'q' to quit): "
      input = $stdin.gets.chomp
      break if input.casecmp('q').zero?

      feature = select_feature(features, input)
      if feature.nil?
        puts 'Invalid selection.'
        next
      end

      toggle_feature(config, features, feature)
    end

    puts 'Done.'
  end

  def print_feature_list(features)
    puts "\n#{'#'.ljust(4)}#{'name'.ljust(35)}#{'display_name'.ljust(30)}enabled"
    features.each_with_index do |feature, index|
      puts "#{(index + 1).to_s.ljust(4)}#{feature['name'].to_s.ljust(35)}#{feature['display_name'].to_s.ljust(30)}#{feature['enabled']}"
    end
  end

  def select_feature(features, input)
    index = Integer(input, exception: false)
    return nil if index.nil? || !index.between?(1, features.length)

    features[index - 1]
  end

  def toggle_feature(config, features, feature)
    print "#{feature['name']} is currently enabled: #{feature['enabled']}. Type 'true' or 'false' to set (anything else cancels): "
    input = $stdin.gets.chomp

    case input
    when 'true'
      new_state = true
    when 'false'
      new_state = false
    else
      puts 'Cancelled.'
      return
    end

    feature['enabled'] = new_state
    config.value = features
    config.save!
    GlobalConfig.clear_cache
    puts "Updated #{feature['name']} to enabled: #{new_state}"
  end
end
# rubocop:enable Metrics/BlockLength
