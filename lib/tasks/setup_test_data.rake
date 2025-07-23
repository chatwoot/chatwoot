namespace :dev do
  desc 'Sets up local test data for a specific service. Usage: rails dev:setup_test_data[service1,service2,store_id]'
  task :setup_test_data, [:service1, :service2, :store_id] => :environment do |_task, args|
    # Collect all non-nil services
    services = []
    store_id = nil
    known_services = %w[instagram whatsapp]

    # Build list of all provided arguments
    all_args = [args[:service1], args[:service2], args[:store_id]].compact

    # If we have arguments, analyze them
    if all_args.any?
      # Check if the last argument is a store_id (not a known service)
      if all_args.length > 1 && !known_services.include?(all_args.last)
        # Last argument is likely a store_id
        store_id = all_args.pop
        services = all_args.select { |arg| known_services.include?(arg) }
      else
        # All arguments are services
        services = all_args.select { |arg| known_services.include?(arg) }
      end
    end

    # Remove duplicate services
    services = services.uniq

    if services.empty?
      puts 'Error: Service name is required. Usage: rails dev:setup_test_data[service_name,store_id]'
      puts 'Available services: instagram, whatsapp'
      puts 'Examples:'
      puts '  rails dev:setup_test_data[instagram]'
      puts '  rails dev:setup_test_data[whatsapp]'
      puts '  rails dev:setup_test_data[instagram,whatsapp]'
      puts '  rails dev:setup_test_data[instagram,whatsapp,STORE123]'
      puts '  rails dev:setup_test_data[whatsapp,STORE123]'
      next
    end

    puts "Setting up test data for #{services.join(', ')}..."
    puts "Using Store ID: #{store_id}" if store_id.present?

    services.each do |svc|
      case svc
      when 'instagram'
        setup_instagram_config(store_id)
      when 'whatsapp'
        setup_whatsapp_config(store_id)
      else
        puts "No setup defined for service: #{svc}"
        puts 'Available services: instagram, whatsapp'
      end
    end
  end

  private

  def setup_instagram_config(store_id = nil)
    puts 'Setting up Instagram configuration for local testing...'
    puts "Store ID: #{store_id}" if store_id.present?

    InstallationConfig.find_or_create_by!(name: 'INSTAGRAM_API_VERSION') do |config|
      config.serialized_value = ActiveSupport::HashWithIndifferentAccess.new(value: 'v22.0')
    end

    InstallationConfig.find_or_create_by!(name: 'INSTAGRAM_APP_ID') do |config|
      config.serialized_value = ActiveSupport::HashWithIndifferentAccess.new(value: '1583830372574438')
    end

    InstallationConfig.find_or_create_by!(name: 'INSTAGRAM_APP_SECRET') do |config|
      config.serialized_value = ActiveSupport::HashWithIndifferentAccess.new(value: 'aba0e3c087e59270464f2b11c7aeadbc')
    end

    InstallationConfig.find_or_create_by!(name: 'INSTAGRAM_VERIFY_TOKEN') do |config|
      config.serialized_value = ActiveSupport::HashWithIndifferentAccess.new(value: 'test-token')
    end

    puts 'Instagram configuration created successfully.'
  end

  def setup_whatsapp_config(store_id = nil)
    puts 'Setting up WhatsApp configuration for local testing...'
    puts "Store ID: #{store_id}" if store_id.present?

    # Create WhatsApp installation configs
    InstallationConfig.find_or_create_by!(name: 'WHATSAPP_API_VERSION') do |config|
      config.serialized_value = ActiveSupport::HashWithIndifferentAccess.new(value: 'v17.0')
    end

    InstallationConfig.find_or_create_by!(name: 'WHATSAPP_APP_ID') do |config|
      config.serialized_value = ActiveSupport::HashWithIndifferentAccess.new(value: 'your-whatsapp-app-id')
    end

    InstallationConfig.find_or_create_by!(name: 'WHATSAPP_APP_SECRET') do |config|
      config.serialized_value = ActiveSupport::HashWithIndifferentAccess.new(value: 'your-whatsapp-app-secret')
    end

    InstallationConfig.find_or_create_by!(name: 'WHATSAPP_VERIFY_TOKEN') do |config|
      config.serialized_value = ActiveSupport::HashWithIndifferentAccess.new(value: 'whatsapp-test-token')
    end

    # Copy WhatsApp channel data
    copy_whatsapp_channel_data(store_id)

    puts 'WhatsApp configuration created successfully.'
  end

  def copy_whatsapp_channel_data(store_id = nil)
    puts 'Copying WhatsApp channel data from production/staging...'
    puts "Store ID: #{store_id}" if store_id.present?

    # Copy WhatsApp channel record - using actual data from your database
    whatsapp_channel = Channel::Whatsapp.find_or_create_by!(phone_number: '+50672925075') do |channel|
      channel.account_id = 3  # Actual account ID from your data
      channel.provider = 'whapi'  # Actual provider from your data
      channel.provider_config = {
        'api_key' => '1gWKRWQZDh12wz3m0nfn72hH5G8K1vY1'  # Actual API key from your data
      }
      channel.message_templates = {}  # Empty as in your actual data
      channel.message_templates_last_updated = Time.current
    end

    # Copy Inbox-Test record from inboxes table - using actual data
    inbox = Inbox.find_or_create_by!(name: 'Inbox-Test') do |inbox_record|
      inbox_record.channel = whatsapp_channel
      inbox_record.account_id = 3  # Actual account ID from your data
      inbox_record.channel_type = 'Channel::Whatsapp'
      inbox_record.enable_auto_assignment = true
      inbox_record.greeting_enabled = false
      inbox_record.greeting_message = nil
      inbox_record.email_address = nil
      inbox_record.working_hours_enabled = false
      inbox_record.out_of_office_message = nil
      inbox_record.timezone = 'UTC'
      inbox_record.enable_email_collect = true
      inbox_record.csat_survey_enabled = false
      inbox_record.allow_messages_after_resolved = true
      inbox_record.auto_assignment_config = {}
      inbox_record.lock_to_single_conversation = false
      inbox_record.portal_id = nil
      inbox_record.sender_name_type = 'friendly'
      inbox_record.business_name = nil
      inbox_record.csat_config = {}
    end

    # Copy corresponding audit record for Inbox-Test - using actual audit data
    if defined?(Enterprise::AuditLog)
      # Find an available user dynamically instead of hardcoding
      available_user = User.first

      if available_user.nil?
        puts 'Warning: No users found in database. Skipping audit log creation.'
      else
        puts "Creating audit log entry with user: #{available_user.email} (ID: #{available_user.id})"

        Enterprise::AuditLog.find_or_create_by!(
          auditable_type: 'Inbox',
          auditable_id: inbox.id,
          action: 'create'
        ) do |audit|
          audit.user_id = available_user.id  # Dynamic user ID
          audit.user_type = 'User'
          audit.username = available_user.email  # Dynamic username
          audit.associated_type = 'Account'
          audit.associated_id = 3  # Actual account ID from your data
          audit.audited_changes = {
            'name' => 'Inbox-Test',
            'timezone' => 'UTC',
            'portal_id' => nil,
            'account_id' => 3,
            'channel_id' => whatsapp_channel.id,
            'csat_config' => {},
            'channel_type' => 'Channel::Whatsapp',
            'business_name' => nil,
            'email_address' => nil,
            'greeting_enabled' => false,
            'greeting_message' => nil,
            'sender_name_type' => 0,
            'csat_survey_enabled' => false,
            'enable_email_collect' => true,
            'out_of_office_message' => nil,
            'working_hours_enabled' => false,
            'auto_assignment_config' => {},
            'enable_auto_assignment' => true,
            'lock_to_single_conversation' => false,
            'allow_messages_after_resolved' => true
          }
          audit.version = 1
          audit.comment = nil
          audit.remote_address = '192.168.65.1'  # Actual IP from your data
          audit.request_uuid = SecureRandom.uuid  # Generate new UUID for testing
          audit.created_at = Time.current
        end
      end
    end

    puts 'WhatsApp channel data copied successfully.'
    puts "Created/Updated WhatsApp channel: #{whatsapp_channel.phone_number}"
    puts "Created/Updated Inbox: #{inbox.name} (ID: #{inbox.id})"
    puts 'Data copied from actual production/staging records.'
  end
end