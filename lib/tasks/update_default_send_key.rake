namespace :chatwoot do
  desc 'Update default send key to Enter for all users'
  task update_default_send_key: :environment do
    puts 'Updating default send key to Enter for all users...'
    
    # Count users that will be updated
    users_to_update = User.where(
      "ui_settings IS NULL OR NOT ui_settings ? 'enter_to_send_enabled' OR ui_settings->>'enter_to_send_enabled' IS NULL"
    ).count
    
    puts "Found #{users_to_update} users to update"
    
    if users_to_update > 0
      # Update users without enter_to_send_enabled setting
      User.where(
        "ui_settings IS NULL OR NOT ui_settings ? 'enter_to_send_enabled' OR ui_settings->>'enter_to_send_enabled' IS NULL"
      ).find_each do |user|
        ui_settings = user.ui_settings || {}
        ui_settings['enter_to_send_enabled'] = true
        ui_settings['editor_message_key'] = 'enter' unless ui_settings['editor_message_key'].present?
        
        user.update_column(:ui_settings, ui_settings)
        print '.'
      end
      
      puts "\nSuccessfully updated #{users_to_update} users"
    else
      puts "No users need to be updated"
    end
    
    puts 'Task completed!'
  end
end
