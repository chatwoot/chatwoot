namespace :conversations do
  desc 'Add pre-sale-query label to conversations with PRE_SALES intent'
  task add_pre_sale_query_label: :environment do
    start_time = Time.current
    puts "Starting pre-sale query label update at #{start_time}"

    # Process each account separately
    Account.find_each do |account|
      begin
        # Create or find the pre-sale-query label for this account
        label = Label.find_or_create_by!(
          account: account,
          title: 'pre-sale-query'
        ) do |l|
          l.description = 'Automatically added to conversations with PRE_SALES intent'
          l.color = '#1f93ff' # Default color
        end

        # Find all conversations with PRE_SALES intent for this account
        conversations = account.conversations.with_intent('PRE_SALES')
        total = conversations.count

        puts "\nProcessing #{total} conversations for account #{account.id}"

        # Add labels in batches to avoid memory issues
        conversations.find_each do |conversation|
          begin
            next if conversation.label_list.include?('pre-sale-query')

            conversation.label_list.add('pre-sale-query')
            conversation.save!
            print '.'
          rescue => e
            puts "\nError processing conversation #{conversation.id}: #{e.message}"
          end
        end
      rescue => e
        puts "\nError processing account #{account.id}: #{e.message}"
      end
    end

    end_time = Time.current
    duration = (end_time - start_time).round(2)

    puts "\nTask completed in #{duration} seconds"
  end
end
