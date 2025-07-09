class EnsureHumanAgentConfigs < ActiveRecord::Migration[7.0]
  def up
    # Đảm bảo cấu hình human_agent cho Facebook Messenger tồn tại
    fb_config = InstallationConfig.find_or_initialize_by(name: 'ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT')
    if fb_config.new_record?
      fb_config.assign_attributes(
        value: false,
        locked: false,
        created_at: Time.current,
        updated_at: Time.current
      )
      fb_config.save!
      puts "✅ Created ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT config"
    else
      puts "✅ ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT config already exists"
    end

    # Đảm bảo cấu hình human_agent cho Instagram tồn tại
    ig_config = InstallationConfig.find_or_initialize_by(name: 'ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')
    if ig_config.new_record?
      ig_config.assign_attributes(
        value: false,
        locked: false,
        created_at: Time.current,
        updated_at: Time.current
      )
      ig_config.save!
      puts "✅ Created ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT config"
    else
      puts "✅ ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT config already exists"
    end

    # Log current status
    puts "\n📊 Current Human Agent Configuration:"
    puts "Facebook Messenger Human Agent: #{fb_config.value}"
    puts "Instagram Human Agent: #{ig_config.value}"
    puts "\n💡 To enable human agent features:"
    puts "1. Access Super Admin panel"
    puts "2. Enable 'Enable human agent' for Facebook Messenger"
    puts "3. Enable 'Enable human agent for instagram channel' for Instagram"
    puts "4. Ensure your Facebook app has been approved for human_agent feature"
  end

  def down
    # Không xóa configs vì có thể đang được sử dụng
    puts "⚠️  Not removing human agent configs as they may be in use"
    puts "If you need to remove them manually:"
    puts "InstallationConfig.where(name: ['ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT', 'ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT']).destroy_all"
  end
end
